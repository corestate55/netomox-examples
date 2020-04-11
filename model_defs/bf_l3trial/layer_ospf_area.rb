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

  def make_nodes
    @as_numbers.each do |asn|
      debug "# areas in #{asn} -- #{@as_area_table.areas_in_as(asn)}"
      @as_area_table.areas_in_as(asn).each do |area|
        name = area_node_name(asn, area)
        # supports are ABR ospf-proc
        supports = @as_area_table.nodes_in(asn, area)
        debug "## asn, area = #{asn}, #{area} : supports: ", supports
        @nodes.push(make_area_node(name, supports))
      end
    end
    @nodes
  end

  def apppend_area_node_tp(link_end)
    node = @nodes.find { |n| n.name == link_end.area_node_name }
    tp = PTermPoint.new(link_end.area_node_tp_name)
    tp.supports.push(%W[ospf-proc #{link_end.node} #{link_end.base_node_tp}])
    node.tps.push(tp)
  end

  def make_links
    @area_links.each do |link|
      debug '# make_links: ', link
      apppend_area_node_tp(link.src)
      apppend_area_node_tp(link.dst)
      add_link link.src.area_node_name, link.src.area_node_tp_name,
               link.dst.area_node_name, link.dst.area_node_tp_name,
               true
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
