# frozen_string_literal: true

require 'netomox'
require_relative 'layer_bgp_base'

# rubocop:disable Metrics/ClassLength
# bgp-proc layer topology converter
class BGPProcTopologyConverter < BGPTopologyConverterBase
  def initialize(opts = {})
    super(opts)
    @ip_owners_table = read_table('ip_owners.csv')
    make_tables
  end

  def make_topology(nws)
    make_bgp_proc_layer(nws)
  end

  private

  def find_edges(node, neighbor_ip)
    @edges_bgp_table.find do |row|
      row[:node] == node && row[:remote_ip] == neighbor_ip.gsub(%r{/\d+}, '')
    end
  end

  def find_interface(node, ip)
    data = @ip_owners_table.find do |row|
      row[:node] == node && row[:ip] == ip
    end
    data.nil? ? ip : data[:interface]
  end

  def make_bgp_proc_tp(node, edge)
    {
      node: node,
      ip: edge[:ip],
      interface: find_interface(node, edge[:ip])
    }
  end

  # rubocop:disable Security/Eval
  def ips_facing_neighbors(node, neighbors_list)
    neighbors = eval(neighbors_list)
    neighbors
      .map { |neighbor_ip| find_edges(node, neighbor_ip) }
      .delete_if(&:nil?)
      .map { |edge| make_bgp_proc_tp(node, edge) }
  end
  # rubocop:enable Security/Eval

  # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
  # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
  def make_bgp_proc_layer_nodes(nws)
    @config_bgp_proc_table.each do |row|
      prefixes = routes_of(row[:node], /.*bgp/)
      tps = ips_facing_neighbors(row[:node], row[:neighbors])
      debug "### check node:#{row[:node]}, " \
            "neighbors:#{row[:neighbors]}, tps:", tps

      nws.network('bgp-proc').register do
        node row[:router_id] do
          lo_count = -1
          ebgp_count = -1
          tps.each do |tp|
            name_count = tps
                         .map { |tmp_tp| tmp_tp[:interface] == tp[:interface] }
                         .count { |value| value == true }
            tp_name = if tp[:interface] =~ /(Loopback|lo)/i
                        # NOTICE: Loopback address is used multiple
                        # in bgp-proc neighbors (iBGP bgp-proc edges).
                        lo_count += 1
                        if lo_count.positive?
                          "#{tp[:ip]}:#{lo_count}"
                        else
                          tp[:ip]
                        end
                      elsif ebgp_count + 2 == name_count && ebgp_count != -1
                        ebgp_count = -1
                        tp[:ip] = "#{tp[:ip]}:#{name_count - 1}"
                      elsif name_count > 1 && ebgp_count + 1 < name_count
                        ebgp_count += 1
                        if ebgp_count.positive?
                          "#{tp[:ip]}:#{ebgp_count}"
                        else
                          tp[:ip]
                        end
                      else
                        tp[:ip]
                      end
            # p "### check1, tp_name:#{tp_name}"
            term_point tp_name do
              support 'layer3', row[:node], tp[:interface]
              attribute(ip_addrs: [tp[:ip]])
            end
          end
          support 'layer3', row[:node]
          attribute(name: row[:node],
                    router_id: row[:router_id],
                    prefixes: prefixes,
                    flags: ['bgp-proc'])
        end
      end
    end
  end
  # rubocop:enable Metrics/MethodLength, Metrics/AbcSize
  # rubocop:enable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity

  def make_bgp_proc_link_param(node, ip)
    interface = find_interface(node, ip)
    {
      node: node,
      router_id: find_router_id(node),
      ip: ip,
      interface: interface,
      key: "#{node}-#{interface}"
    }
  end

  def counted_name(name, count)
    count.positive? ? "#{name}:#{count}" : name
  end

  def count_tp_ref(key)
    @tp_ref_count[key] = -1 if @tp_ref_count[key].nil?
    @tp_ref_count[key] += 1
  end

  # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
  def make_bgp_proc_link_tp(row)
    src = make_bgp_proc_link_param(row[:node], row[:ip])
    dst = make_bgp_proc_link_param(row[:remote_node], row[:remote_ip])
    forward_key = "#{src[:key]}-#{dst[:key]}"
    reverse_key = "#{dst[:key]}-#{src[:key]}"
    debug "###### fwd_key=#{forward_key}, rev_key=#{reverse_key}"
    if @link_ref_count[forward_key].nil? && @link_ref_count[reverse_key].nil?
      count_tp_ref(src[:key])
      count_tp_ref(dst[:key])
      @link_ref_count[forward_key] = [
        @tp_ref_count[src[:key]], @tp_ref_count[dst[:key]]
      ]
      debug "### rev/fwd not found, #{@link_ref_count[forward_key]}"
    elsif @link_ref_count[forward_key].nil? # exists reverse
      @link_ref_count[forward_key] = @link_ref_count[reverse_key].reverse
      debug "### rev found (fwd not found), #{@link_ref_count[forward_key]}"
    else
      warn 'WARNING: duplicated link?'
    end

    src[:ip] = counted_name(src[:ip], @link_ref_count[forward_key][0])
    dst[:ip] = counted_name(dst[:ip], @link_ref_count[forward_key][1])

    # debug "### check2, tp_ref_count: ", @tp_ref_count
    # debug "### check2, link_ref_count: ", @link_ref_count
    debug "### src: #{src[:node]}, #{src[:ip]}, #{src[:interface]}"
    debug "### dst: #{dst[:node]}, #{dst[:ip]}, #{dst[:interface]}"
    [src, dst]
  end
  # rubocop:enable Metrics/MethodLength, Metrics/AbcSize

  def make_bgp_proc_layer_links(nws)
    @tp_ref_count = {}
    @link_ref_count = {}
    @edges_bgp_table.each do |row|
      src, dst = make_bgp_proc_link_tp(row)
      nws.network('bgp-proc').register do
        link src[:router_id], src[:ip], dst[:router_id], dst[:ip]
      end
    end
  end

  def make_bgp_proc_layer(nws)
    nws.register do
      network 'bgp-proc' do
        type Netomox::NWTYPE_L3
      end
    end
    make_bgp_proc_layer_nodes(nws)
    make_bgp_proc_layer_links(nws)
  end
end
# rubocop:enable Metrics/ClassLength
