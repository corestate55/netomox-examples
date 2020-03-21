# frozen_string_literal: true

require 'netomox'
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

    @config_bgp_proc_table = ConfigBGPProcTable.new(@target)
    @config_ospf_area_table = ConfigOSPFAreaTable.new(@target)

    make_tables
  end

  def make_topology(nws)
    make_bgp_as_layer(nws)
  end

  protected

  # rubocop:disable Metrics/MethodLength
  def make_tables
    super

    table_of = {
      config_bgp_proc: @config_bgp_proc_table,
      config_ospf_area: @config_ospf_area_table,
      as_numbers: @as_numbers,
      edges_bgp: @edges_bgp_table
    }

    @nodes_in_as = NodesInASTable.new(@target, table_of)
    debug '# nodes_in_as: ', @nodes_in_as

    table_of[:nodes_in_as] = @nodes_in_as
    @areas_in_as = AreasInASTable.new(@target, table_of)
    debug '# areas_in_as: ', @areas_in_as
    @links_inter_as = LinksInterASTable.new(@target, table_of)
    debug '# links_inter_as: ', @links_inter_as
  end
  # rubocop:enable Metrics/MethodLength

  private

  # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
  def make_bgp_as_layer_nodes(nws)
    @as_numbers.each do |asn|
      tps = @links_inter_as.interfaces_inter_as(asn)
      debug "### check: AS:#{asn}, tps:", tps
      inter_routers = @nodes_in_as[asn].inter_area_routers
      debug '### inter_area_routers: ', inter_routers

      areas = @areas_in_as[asn]
      router_ids = @nodes_in_as[asn].router_ids_in_as

      nws.network('bgp-as').register do
        # AS as node
        node "as#{asn}" do
          # interface of inter-AS link and its support-tp
          tps.each do |tp|
            term_point tp.interface do
              support 'bgp-proc', tp.router_id, tp.interface
              attribute(ip_addrs: [tp.interface])
            end
          end
          # support-node to ospf layer
          areas.each do |area|
            support 'ospf-area', "as#{asn}-area#{area}" # ospf area
          end
          inter_routers.each do |router|
            support 'ospf-area', router[:node] # inter-area-router
          end
          # support-node to bgp-proc layer
          router_ids.each do |router_id|
            support 'bgp-proc', router_id
          end
        end
      end
    end
  end
  # rubocop:enable Metrics/MethodLength, Metrics/AbcSize

  def make_bgp_as_layer_links(nws)
    @links_inter_as.each do |as_link|
      nws.network('bgp-as').register do
        link "as#{as_link.src.as}", as_link.src.interface,
             "as#{as_link.dst.as}", as_link.dst.interface
      end
    end
  end

  def make_bgp_as_layer(nws)
    nws.register { network 'bgp-as' }
    make_bgp_as_layer_nodes(nws)
    make_bgp_as_layer_links(nws)
  end
end
