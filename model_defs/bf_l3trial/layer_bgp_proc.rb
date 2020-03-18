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

  def tp_name_count(term_points, term_point)
    term_points
      .map { |tp| tp[:interface] == term_point[:interface] }
      .count { |value| value == true }
  end

  def select_tp_name(count, name)
    count.positive? ? "#{name}:#{count}" : name
  end

  # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
  def make_tp_name(term_point, count_of)
    if term_point[:interface] =~ /(Loopback|lo)/i
      # NOTICE: Loopback address is used multiple
      # in bgp-proc neighbors (iBGP bgp-proc edges).
      count_of[:lo] += 1
      select_tp_name(count_of[:lo], term_point[:ip])
    elsif count_of[:ebgp] + 2 == count_of[:name] && count_of[:ebgp] != -1
      count_of[:ebgp] = -1
      term_point[:ip] = "#{term_point[:ip]}:#{count_of[:name] - 1}"
    elsif count_of[:name] > 1 && count_of[:ebgp] + 1 < count_of[:name]
      count_of[:ebgp] += 1
      select_tp_name(count_of[:ebgp], term_point[:ip])
    else
      term_point[:ip]
    end
  end
  # rubocop:enable Metrics/MethodLength, Metrics/AbcSize

  def bgp_proc_node_attribute(row)
    {
      name: row[:node],
      router_id: row[:router_id],
      prefixes: routes_of(row[:node], /.*bgp/),
      flags: ['bgp-proc']
    }
  end

  # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
  def make_bgp_proc_layer_tps(nws)
    @config_bgp_proc_table.each do |row|
      tps = ips_facing_neighbors(row[:node], row[:neighbors])
      debug "### check node:#{row[:node]}, " \
            "neighbors:#{row[:neighbors]}, tps:", tps

      count_of = { lo: -1, ebgp: -1 }
      tps.each do |tp|
        count_of[:name] = tp_name_count(tps, tp)
        tp_name = make_tp_name(tp, count_of)

        nws.network('bgp-proc').register do
          node(row[:router_id]).register do
            # p "### check1, tp_name:#{tp_name}"
            term_point tp_name do
              support 'layer3', row[:node], tp[:interface]
              attribute(ip_addrs: [tp[:ip]])
            end
          end
        end
      end
    end
  end
  # rubocop:enable Metrics/MethodLength, Metrics/AbcSize

  def make_bgp_proc_layer_nodes(nws)
    @config_bgp_proc_table.each do |row|
      node_attr = bgp_proc_node_attribute(row)

      nws.network('bgp-proc').register do
        node row[:router_id] do
          support 'layer3', row[:node]
          attribute(node_attr)
        end
      end
    end
    make_bgp_proc_layer_tps(nws)
  end

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
