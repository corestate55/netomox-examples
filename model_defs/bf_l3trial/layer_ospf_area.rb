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
  end

  def make_topology(nws)
    make_ospf_area_layer(nws)
  end

  private

  # name of ospf-are node in ospf-area layer
  def area_node_name(asn, area)
    "as#{asn}-area#{area}"
  end

  # rubocop:disable Metrics/MethodLength
  def make_ospf_area_layer_nodes(nws)
    @as_numbers.each do |asn|
      debug "# areas in #{asn} -- #{@as_area_table.areas_in_as(asn)}"
      @as_area_table.areas_in_as(asn).each do |area|
        support_nodes = @as_area_table.nodes_in(asn, area)
        debug "## asn, area = #{asn}, #{area}"
        debug support_nodes

        node_name = area_node_name(asn, area)
        nws.network('ospf-area').register do
          node node_name do
            # support node
            support_nodes.each do |support_node|
              support 'ospf-proc', support_node
            end
          end
        end
      end
    end
  end
  # rubocop:enable Metrics/MethodLength

  # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
  def make_ospf_area_layer_links(nws)
    support_count = {}
    @area_links.each do |link|
      debug '# link: ', link

      nws.network('ospf-area').register do
        node link.node do
          term_point link.node_tp do
            support 'ospf-proc', link.node, link.node_tp
          end
          # avoid duplicate support-node
          key = link.as_node_key
          support_count[key] = support_count[key] || 0
          support 'ospf-proc', link.node if support_count[key] < 1
          support_count[key] += 1
        end
        node link.area do
          term_point link.area_tp
        end
        bdlink link.node, link.node_tp, link.area, link.area_tp
      end
    end
  end
  # rubocop:enable Metrics/MethodLength, Metrics/AbcSize

  def make_ospf_area_layer(nws)
    nws.register { network 'ospf-area' }
    make_ospf_area_layer_nodes(nws)
    make_ospf_area_layer_links(nws)
  end
end
