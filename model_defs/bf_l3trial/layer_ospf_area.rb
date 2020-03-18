# frozen_string_literal: true

require 'netomox'
require_relative 'layer_ospf_base'

# rubocop:disable Metrics/ClassLength
# ospf-area layer topology converter
class OSPFAreaTopologyConverter < OSPFTopologyConverterBase
  def initialize(opts = {})
    super(opts)
    make_tables
  end

  def make_topology(nws)
    make_ospf_area_layer(nws)
  end

  private

  def make_tables
    super
    @area_links = make_ospf_area_links
    debug '# ospf_area_link: ', @area_links
  end

  def inter_area_nodes
    paths = @as_area_table.map { |r| "#{r[:as]}__#{r[:node]}" }
    paths
      .sort
      .reject { |p| paths.index(p) == paths.rindex(p) }
      .uniq
      .map do |path|
      path =~ /(.*)__(.*)/
      { as: Regexp.last_match(1).to_i, node: Regexp.last_match(2) }
    end
  end

  def nodes_in(asn, area)
    @as_area_table
      .find_all { |row| row[:as] == asn && row[:area] == area }
      .map { |row| row[:node] }
      .sort.uniq
  end

  def areas_in_as(asn)
    @as_area_table
      .find_all { |row| row[:as] == asn }
      .map { |row| row[:area] }
      .find_all { |area| area >= 0 } # area 0 MUST be backbone area.
      .sort.uniq
  end

  def area_node_connections
    inter_area_nodes.map do |as_node_pair|
      @as_area_table.find_all do |r|
        r[:as] == as_node_pair[:as] && r[:node] == as_node_pair[:node]
      end
    end
  end

  def area_link_data(area_node_pair, interface, area_tp_count)
    {
      as: area_node_pair[:as],
      node: area_node_pair[:node],
      node_tp: interface[:interface],
      area: "as#{area_node_pair[:as]}-area#{area_node_pair[:area]}",
      area_tp: "p#{area_tp_count}"
    }
  end

  # rubocop:disable Metrics/MethodLength
  def make_ospf_area_links
    # find router and its interface that connects multiple-area
    area_node_pairs = area_node_connections
    count_area_tp = {}
    links = area_node_pairs.flatten.map do |area_node_pair|
      area_node_pair[:interfaces].map do |interface|
        area_key = "#{area_node_pair[:as]}_#{area_node_pair[:area]}"
        count_area_tp[area_key] = count_area_tp[area_key] || 0
        count_area_tp[area_key] += 1
        area_link_data(area_node_pair, interface, count_area_tp[area_key])
      end
    end
    links.flatten
  end
  # rubocop:enable Metrics/MethodLength

  # rubocop:disable Metrics/MethodLength
  def make_ospf_area_layer_nodes(nws)
    @as_numbers.each do |asn|
      debug "# areas in #{asn} -- #{areas_in_as(asn)}"
      areas_in_as(asn).each do |area|
        support_nodes = nodes_in(asn, area)
        debug "## asn, area = #{asn}, #{area}"
        debug support_nodes

        nws.network('ospf-area').register do
          node "as#{asn}-area#{area}" do
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
        node link[:node] do
          term_point link[:node_tp]
          # avoid duplicate support-node
          key = "#{link[:as]}-#{link[:node]}"
          support_count[key] = support_count[key] || 0
          support 'ospf-proc', link[:node] if support_count[key] < 1
          support_count[key] += 1
        end
        node link[:area] do
          term_point link[:area_tp]
        end
        bdlink link[:node], link[:node_tp], link[:area], link[:area_tp]
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
# rubocop:enable Metrics/ClassLength
