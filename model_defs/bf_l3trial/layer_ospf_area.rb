# frozen_string_literal: true

require 'netomox'
require_relative 'layer_ospf_base'
require_relative 'csv/as_area_links_table'

# ospf-area layer topology converter
class OSPFAreaTopologyConverter < OSPFTopologyConverterBase
  def initialize(opts = {})
    super(opts)

    table_of = { as_area: @as_area_table }
    @area_links = ASAreaLinkTable.new(@target, table_of, @use_debug)
    debug '# ospf_area_link: ', @area_links
    make_networks
  end

  private

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

  def make_link_proc_edge_tp(link)
    ptp = PTermPoint.new(link.node_tp)
    ptp.supports.push(['ospf-proc', link.node, link.node_tp])
    ptp
  end

  def make_link_proc_edge(link)
    pnode = PNode.new(link.node)
    pnode.tps.push(make_link_proc_edge_tp(link))
    pnode.supports.push(['ospf-proc', link.node])
    pnode
  end

  def make_link_area_edge(link)
    # OSPF-Area node is already exists (by #make_area_nodes)
    pnode = @nodes.find { |n| n.name == link.area }
    pnode.tps.push(PTermPoint.new(link.area_tp))
    pnode
  end

  def make_link_edges
    @area_links.each do |link|
      debug '# link: ', link
      @nodes.push(make_link_proc_edge(link))
      @nodes.push(make_link_area_edge(link))
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
    @networks.networks.push(@network)
    @networks
  end
end
