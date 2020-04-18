# frozen_string_literal: true

require_relative 'layer_bgp_base'
require_relative 'csv/config_bgp_proc_table'
require_relative 'csv/config_ospf_area_table'
require_relative 'csv/nodes_in_as_table'
require_relative 'csv/areas_in_as_table'
require_relative 'csv/links_inter_as_table'

# bgp-as layer topology converter
class BGPASTopologyConverter < BGPTopologyConverterBase
  def initialize(opts = {})
    super(opts)

    setup_config_ospf_area_table
    setup_nodes_in_as_table # MUST after config_ospf_area_table
    setup_areas_in_as_table # MUST after nodes_in_as_table
    setup_links_inter_as_table
    make_networks
  end

  private

  def setup_config_ospf_area_table
    table_of = {
      ip_owners: @ip_owners_table,
      routes: @routes_table
    }
    @config_ospf_area_table = ConfigOSPFAreaTable.new(@target, table_of)
    debug '# config_ospf_area: ', @config_ospf_area_table
  end

  def setup_nodes_in_as_table
    table_of = {
      as_numbers: @as_numbers,
      edges_bgp: @edges_bgp_table,
      config_bgp_proc: @config_bgp_proc_table,
      config_ospf_area: @config_ospf_area_table
    }
    @nodes_in_as = NodesInASTable.new(@target, table_of)
    debug '# nodes_in_as: ', @nodes_in_as
  end

  def setup_areas_in_as_table
    table_of = { nodes_in_as: @nodes_in_as }
    @areas_in_as = AreasInASTable.new(@target, table_of)
    debug '# areas_in_as: ', @areas_in_as
  end

  def setup_links_inter_as_table
    table_of = { edges_bgp: @edges_bgp_table }
    @links_inter_as = LinksInterASTable.new(@target, table_of)
    debug '# links_inter_as: ', @links_inter_as
  end

  def make_as_node_tp(term_point)
    ptp = PTermPoint.new(term_point.interface)
    ptp.supports.push(['bgp-proc', term_point.router_id, term_point.interface])
    ptp.attribute = { ip_addrs: [term_point.interface] }
    ptp
  end

  def make_as_node_tps(asn)
    # interface of inter-AS link and its support-tp
    tps = @links_inter_as.interfaces_inter_as(asn)
    debug "### check: AS:#{asn}, tps:", tps
    tps.map { |tp| make_as_node_tp(tp) }
  end

  def areas_supports(asn)
    @areas_in_as[asn].map do |area|
      ['ospf-area', "as#{asn}-area#{area}"] # ospf area
    end
  end

  def inter_router_supports(asn)
    inter_routers = @nodes_in_as[asn].inter_area_routers
    debug '### inter_area_routers: ', inter_routers
    inter_routers.map do |router|
      ['ospf-area', router[:node]] # inter-area-router
    end
  end

  def router_id_supports(asn)
    @nodes_in_as[asn].router_ids.map do |router_id|
      ['bgp-proc', router_id]
    end
  end

  def make_as_node_supports(asn)
    [
      areas_supports(asn),
      inter_router_supports(asn),
      router_id_supports(asn)
    ].flatten(1)
  end

  def make_as_node(asn)
    pnode = PNode.new("as#{asn}")
    pnode.tps = make_as_node_tps(asn)
    pnode.supports = make_as_node_supports(asn)
    pnode
  end

  def make_nodes
    @nodes = @as_numbers.map { |asn| make_as_node(asn) }
  end

  def make_links
    @links_inter_as.each do |as_link|
      add_link "as#{as_link.src.as}", as_link.src.interface,
               "as#{as_link.dst.as}", as_link.dst.interface,
               false
    end
    @links
  end

  def make_networks
    @network = PNetwork.new('bgp-as')
    @network.nodes = make_nodes
    @network.links = make_links
    @networks.push(@network)
    @networks
  end
end
