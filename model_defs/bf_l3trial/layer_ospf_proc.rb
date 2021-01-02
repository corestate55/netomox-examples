# frozen_string_literal: true

require_relative 'layer_ospf_base'
require_relative 'csv/edges_ospf_table'

# ospf-proc layer topology converter
class OSPFProcTopologyConverter < OSPFTopologyConverterBase
  def initialize(opts = {})
    super(opts)

    setup_edges_ospf_table
    make_networks
  end

  private

  def setup_edges_ospf_table
    # @edges_ospf_table uses @as_area_table,
    # put after super.make_tables (@as_area_table)
    table_of = { as_area: @as_area_table }
    @edges_ospf_table = EdgesOSPFTable.new(@target, table_of)
  end

  def make_proc_node_tp(term_point, as_area_rec)
    debug '# ospf_proc_layer tp: ', term_point, as_area_rec
    ptp = PTermPoint.new(term_point.interface)
    ptp.supports.push(['layer3', as_area_rec.node, term_point.interface])
    # NOTICE: appending ospf-area info that interface joins.
    # In nature, `ip_addrs` field contains only IP-format string, it becomes a type validation error.
    # This implementation is experimental.
    # It must be used as a new network type (ospf-type network) and its attributes instead of layer3-network-type.
    # (but not implemented the ospf-type schemas yet.)
    ptp.attribute = { ip_addrs: ["area#{as_area_rec.area}:#{term_point.ip}"] }
    ptp
  end

  def make_proc_node_tps(as_area_rec)
    as_area_rec.interfaces.map { |tp| make_proc_node_tp(tp, as_area_rec) }
  end

  def make_proc_node(as_area_rec)
    pnode = find_or_new_node(as_area_rec.node)
    # append tps if found in existence node.
    pnode.tps.concat(make_proc_node_tps(as_area_rec))
    pnode.supports.push(['layer3', as_area_rec.node])
    pnode.supports.uniq!
    pnode.attribute = as_area_rec.ospf_proc_node_attribute
    pnode
  end

  def make_nodes
    @as_area_table.records_has_area.each do |rec|
      debug '# ospf_proc_layer node: ', rec
      add_node_if_new(make_proc_node(rec))
    end
    @nodes
  end

  def make_links
    @edges_ospf_table.proc_links.each do |p_link|
      add_link p_link.src.node, p_link.src.interface,
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
    @networks.push(@network)
    @networks
  end
end
