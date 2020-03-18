# frozen_string_literal: true

require 'netomox'
require_relative 'layer_ospf_base'

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

  # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
  def make_ospf_area_links
    # find router and its interface that connects multiple-area
    target_rows = inter_area_nodes.map do |as_node_pair|
      @as_area_table.find_all do |r|
        r[:as] == as_node_pair[:as] && r[:node] == as_node_pair[:node]
      end
    end
    count_area_tp = {}
    links = target_rows.flatten.map do |row|
      row[:interfaces].map do |interface|
        area_key = "#{row[:as]}_#{row[:area]}"
        count_area_tp[area_key] = count_area_tp[area_key] || 0
        count_area_tp[area_key] += 1
        {
          as: row[:as],
          source: row[:node],
          source_tp: interface[:interface],
          destination: "as#{row[:as]}-area#{row[:area]}",
          destination_tp: "p#{count_area_tp[area_key]}"
        }
      end
    end
    links.flatten
  end
  # rubocop:enable Metrics/MethodLength, Metrics/AbcSize

  # rubocop:disable Metrics/MethodLength
  def make_ospf_area_layer_nodes(nws)
    @as_numbers.each do |asn|
      debug "# areas in #{asn} -- #{areas_in_as(asn)}"
      areas_in_as(asn).each do |area|
        support_nodes = nodes_in(asn, area)
        debug "## asn,area = #{asn}, #{area}"
        debug support_nodes
        nws.network('ospf').register do
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
    @area_links.each do |link|
      nws.network('ospf').register do
        node link[:source] do
          term_point link[:source_tp]
        end
        node link[:destination] do
          term_point link[:destination_tp]
        end
        bdlink link[:source], link[:source_tp],
               link[:destination], link[:destination_tp]
      end
    end
  end
  # rubocop:enable Metrics/MethodLength, Metrics/AbcSize

  def make_ospf_area_layer(nws)
    nws.register { network 'ospf' }
    make_ospf_area_layer_nodes(nws)
    make_ospf_area_layer_links(nws)
  end
end
