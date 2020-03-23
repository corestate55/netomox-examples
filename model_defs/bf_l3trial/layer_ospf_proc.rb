# frozen_string_literal: true

require 'netomox'
require_relative 'layer_ospf_base'
require_relative 'csv/edges_ospf_table'

# ospf-proc layer topology converter
class OSPFProcTopologyConverter < OSPFTopologyConverterBase
  def initialize(opts = {})
    super(opts)

    # @edges_ospf_table uses @as_area_table,
    # put after super.make_tables (@as_area_table)
    table_of = { as_area: @as_area_table }
    @edges_ospf_table = EdgesOSPFTable.new(@target, table_of)
    make_networks
  end

  private

  def make_ospf_proc_tps(as_area)
    as_area.interfaces.map do |tp|
      ptp = PTermPoint.new(tp.interface)
      ptp.supports.push(['layer3', as_area.node, tp.interface])
      ptp.attribute = { ip_addrs: [tp.ip] }
      ptp
    end
  end

  def make_ospf_proc_node(as_area)
    pnode = PNode.new(as_area.node)
    pnode.tps = make_ospf_proc_tps(as_area)
    pnode.supports.push(['layer3', as_area.node])
    pnode.attribute = as_area.ospf_proc_node_attribute
    pnode
  end

  def make_nodes
    @as_area_table.records_has_area.each do |rec|
      debug '# ospf_layer node: ', rec
      @nodes.push(make_ospf_proc_node(rec))
    end
    @nodes
  end

  def make_links
    @edges_ospf_table.proc_links.each do |p_link|
      add_link  p_link.src.node, p_link.src.interface,
                p_link.dst.node, p_link.dst.interface,
                false
    end
    @links
  end

  def make_networks
    @network = PNetwork.new('ospf-proc')
    @network.type = Netomox::NWTYPE_L3
    @network.nodes = make_nodes
    @network.links = make_links
    @networks.networks.push(@network)
    @networks
  end
end
