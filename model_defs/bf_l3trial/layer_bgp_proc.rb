# frozen_string_literal: true

require 'netomox'
require_relative 'layer_bgp_base'
require_relative 'layer_bgp_utils'
require_relative 'csv/config_bgp_proc_table'

# bgp-proc layer topology converter
class BGPProcTopologyConverter < BGPTopologyConverterBase
  def initialize(opts = {})
    super(opts)
  end

  def make_topology(nws)
    make_bgp_proc_layer(nws)
  end

  private

  # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
  def make_bgp_proc_layer_tps(layer_bgp_proc)
    @config_bgp_proc_table.each do |rec|
      tps = rec.ips_facing_neighbors # returns Array of BGPProcEdge
      debug "### check node:#{rec.node}, " \
            "neighbors:#{rec.neighbors}, tps:", tps

      tp_name_counter = TPNameCounter.new(@use_debug)
      tps.each do |tp|
        tp_name = tp_name_counter.make_tp_name(tps, tp)

        layer_bgp_proc.node(rec.router_id).register do
          # p "### check1, tp_name:#{tp_name}"
          term_point tp_name do
            support 'layer3', rec.node, tp.interface
            attribute(ip_addrs: [tp.ip])
          end
        end
      end
    end
  end
  # rubocop:enable Metrics/MethodLength, Metrics/AbcSize

  def make_bgp_proc_layer_nodes(layer_bgp_proc)
    @config_bgp_proc_table.each do |rec|
      node_attr = rec.bgp_proc_node_attribute
      layer_bgp_proc.node(rec.router_id) do
        support 'layer3', rec.node
        attribute(node_attr)
      end
    end
  end

  def make_bgp_proc_layer_links(layer_bgp_proc)
    @edges_bgp_table.make_proc_links.each do |proc_link|
      layer_bgp_proc.register do
        link proc_link.src.router_id, proc_link.src.ip,
             proc_link.dst.router_id, proc_link.dst.ip
      end
    end
  end

  def make_bgp_proc_layer(nws)
    nws.register do
      network 'bgp-proc' do
        type Netomox::NWTYPE_L3
      end
    end
    layer_bgp_proc = nws.network('bgp-proc')
    make_bgp_proc_layer_nodes(layer_bgp_proc)
    make_bgp_proc_layer_tps(layer_bgp_proc)
    make_bgp_proc_layer_links(layer_bgp_proc)
  end
end
