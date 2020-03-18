# frozen_string_literal: true

require 'netomox'
require_relative 'layer_bgp_base'

# bgp-as layer topology converter
class BGPASTopologyConverter < BGPTopologyConverterBase
  def initialize(opts = {})
    super(opts)
    @config_ospf_area_table = read_table('config_ospf_area.csv')
    make_tables
  end

  def make_topology(nws)
    make_bgp_layer(nws)
  end

  private

  def make_tables
    super
    @areas_in_as = make_areas_in_as
    debug '# areas_in_as: ', @areas_in_as
    @links_inter_as = make_links_inter_as
    debug '# links_inter_as: ', @links_inter_as
  end

  def find_areas(nodes)
    areas = nodes.map do |node|
      @config_ospf_area_table
        .find_all { |row| row[:node] == node }
        .map { |row| row[:area] }
    end
    areas.flatten.sort.uniq
  end

  def make_areas_in_as
    areas_in_as = {}
    @nodes_in_as.each_pair do |asn, nodes|
      areas_in_as[asn] = find_areas(nodes)
    end
    areas_in_as
  end

  def make_as_link_tp(asn, node, interface)
    {
      as: asn, node: node, interface: interface,
      router_id: find_router_id(node)
    }
  end

  def make_as_link(link)
    {
      source: make_as_link_tp(
        link[:as_number], link[:node], link[:ip]
      ),
      destination: make_as_link_tp(
        link[:remote_as_number], link[:remote_node], link[:remote_ip]
      )
    }
  end

  def make_links_inter_as
    @edges_bgp_table
      .find_all { |row| row[:as_number] != row[:remote_as_number] }
      .map { |link| make_as_link(link) }
  end

  def router_ids_in_as(asn)
    @nodes_in_as[asn].map { |node| find_router_id(node) }
  end

  def interfaces_inter_as(asn)
    @links_inter_as
      .find_all { |link| link[:source][:as] == asn }
      .map { |link| link[:source] }
  end

  # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
  def make_bgp_layer_nodes(nws)
    @as_numbers.each do |asn|
      tps = interfaces_inter_as(asn)
      debug "### check: AS:#{asn}, tps:", tps
      areas = @areas_in_as[asn]
      router_ids = router_ids_in_as(asn)

      nws.network('bgp').register do
        # AS as node
        node "as#{asn}" do
          # interface of inter-AS link and its support-tp
          tps.each do |tp|
            term_point tp[:interface] do
              support 'bgp-proc', tp[:router_id], tp[:interface]
              attribute(ip_addrs: [tp[:interface]])
            end
          end
          # support-node to ospf layer
          areas.each do |area|
            support 'ospf', "as#{asn}-area#{area}"
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

  def make_bgp_layer_links(nws)
    @links_inter_as.each do |link_row|
      src = link_row[:source]
      dst = link_row[:destination]
      nws.network('bgp').register do
        link "as#{src[:as]}", src[:interface], "as#{dst[:as]}", dst[:interface]
      end
    end
  end

  def make_bgp_layer(nws)
    nws.register { network 'bgp' }
    make_bgp_layer_nodes(nws)
    make_bgp_layer_links(nws)
  end
end
