# frozen_string_literal: true

require 'netomox'
require_relative 'layer_bgp_base'
require_relative 'csv/config_bgp_proc_table'
# bgp-proc layer topology converter
class BGPProcTopologyConverter < BGPTopologyConverterBase
  def initialize(opts = {})
    super(opts)

    @config_bgp_proc_table = ConfigBGPProcTable.new(@target)

    make_tables
  end

  def make_topology(nws)
    make_bgp_proc_layer(nws)
  end

  private

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

  # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
  def make_bgp_proc_layer_tps(nws)
    @config_bgp_proc_table.each do |rec|
      tps = rec.ips_facing_neighbors
      debug "### check node:#{rec.node}, " \
            "neighbors:#{rec.neighbors}, tps:", tps

      count_of = { lo: -1, ebgp: -1 }
      tps.each do |tp|
        count_of[:name] = tp_name_count(tps, tp)
        tp_name = make_tp_name(tp, count_of)

        nws.network('bgp-proc').register do
          node(rec.router_id).register do
            # p "### check1, tp_name:#{tp_name}"
            term_point tp_name do
              support 'layer3', rec.node, tp[:interface]
              attribute(ip_addrs: [tp[:ip]])
            end
          end
        end
      end
    end
  end
  # rubocop:enable Metrics/MethodLength, Metrics/AbcSize

  def make_bgp_proc_layer_nodes(nws)
    @config_bgp_proc_table.each do |rec|
      node_attr = rec.bgp_proc_node_attribute
      nws.network('bgp-proc').register do
        node rec.router_id do
          support 'layer3', rec.node
          attribute(node_attr)
        end
      end
    end
    make_bgp_proc_layer_tps(nws)
  end

  def make_bgp_proc_layer_links(nws)
    @edges_bgp_table.make_proc_links.each do |proc_link|
      nws.network('bgp-proc').register do
        link proc_link[:source].router_id, proc_link[:source].ip,
             proc_link[:destination].router_id, proc_link[:destination].ip
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
