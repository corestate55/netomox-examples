# frozen_string_literal: true

require_relative 'layer_ospf_base'
require_relative 'csv/as_area_links_table'

# ospf-area layer topology converter
class OSPFAreaTopologyConverter < OSPFTopologyConverterBase
  def initialize(opts = {})
    super(opts)

    setup_area_links_table
    make_networks
  end

  private

  def setup_area_links_table
    table_of = { as_area: @as_area_table }
    @area_links = ASAreaLinkTable.new(@target, table_of, @use_debug)
    debug '# ospf_area_link: ', @area_links
  end

  # name of ospf-are node in ospf-area layer
  def area_node_name(asn, area)
    "as#{asn}-area#{area}"
  end

  def make_area_node(name, supports)
    pnode = PNode.new(name)
    pnode.supports = supports.map { |s| ['ospf-proc', s] }
    pnode
  end

  def make_area_nodes
    @as_numbers.each do |asn|
      debug "# areas in #{asn} -- #{@as_area_table.areas_in_as(asn)}"
      @as_area_table.areas_in_as(asn).each do |area|
        name = area_node_name(asn, area)
        supports = @as_area_table.nodes_in(asn, area)
        debug "## asn, area = #{asn}, #{area} : supports: ", supports
        @nodes.push(make_area_node(name, supports))
      end
    end
  end

  def make_link_edge_tp(node_name, tp_name, is_node)
    ptp = PTermPoint.new(tp_name)
    ptp.supports.push(['ospf-proc', node_name, tp_name]) if is_node
    ptp
  end

  def make_link_edge(node_name, tp_name, is_node = true)
    pnode = find_or_new_node(node_name)
    pnode.tps.push(make_link_edge_tp(node_name, tp_name, is_node))
    pnode.supports.push(['ospf-proc', node_name]) if is_node
    pnode.supports.uniq!
    pnode
  end

  def make_link_edges
    @area_links.each do |link|
      debug '# link: ', link
      add_node_if_new(make_link_edge(link.node, link.node_tp))
      add_node_if_new(make_link_edge(link.area, link.area_tp, false))
    end
  end

  def make_nodes
    make_area_nodes
    make_link_edges
    @nodes
  end

  def make_links
    @area_links.each do |link|
      debug '# link: ', link
      add_link link.node, link.node_tp, link.area, link.area_tp
    end
    @links
  end

  def make_networks
    @network = PNetwork.new('ospf-area')
    @network.nodes = make_nodes
    @network.links = make_links
    @networks.push(@network)
    @networks
  end
end
