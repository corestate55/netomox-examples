# frozen_string_literal: true

require_relative 'layer_bgp_base'
require_relative 'layer_bgp_utils'
require_relative 'csv/config_bgp_proc_table'

# bgp-proc layer topology converter
class BGPProcTopologyConverter < BGPTopologyConverterBase
  def initialize(opts = {})
    super(opts)
    make_networks
  end

  private

  def make_proc_node_tp(rec, term_point, tp_name)
    debug '#### tp name: ', tp_name
    ptp = PTermPoint.new(tp_name)
    ptp.supports.push(['layer3', rec.node, term_point.interface])
    ptp.attribute = { ip_addrs: [term_point.ip] }
    ptp
  end

  def make_proc_node_tps(rec)
    tps = rec.ips_facing_neighbors # returns Array of BGPProcEdge
    debug "### check node:#{rec.node}, " \
            "neighbors:#{rec.neighbors}, tps:", tps
    tp_name_counter = TPNameCounter.new(tps)
    tps.map do |tp|
      tp_name = tp_name_counter.tp_name(tp)
      make_proc_node_tp(rec, tp, tp_name)
    end
  end

  def make_proc_node(rec)
    pnode = PNode.new(rec.router_id)
    pnode.supports.push(['layer3', rec.node])
    pnode.attribute = rec.bgp_proc_node_attribute
    pnode.tps = make_proc_node_tps(rec)
    pnode
  end

  def make_nodes
    @nodes = @config_bgp_proc_table.map do |rec|
      make_proc_node(rec)
    end
  end

  def make_links
    @edges_bgp_table.make_proc_links.each do |proc_link|
      add_link proc_link.src.router_id, proc_link.src.ip,
               proc_link.dst.router_id, proc_link.dst.ip,
               false
    end
    @links
  end

  def make_networks
    @network = PNetwork.new('bgp-proc')
    @network.type = Netomox::NWTYPE_L3
    @network.nodes = make_nodes
    @network.links = make_links
    @networks.push(@network)
    @networks
  end
end
