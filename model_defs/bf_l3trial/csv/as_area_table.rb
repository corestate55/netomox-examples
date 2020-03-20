# frozen_string_literal: true

require 'forwardable'
require_relative 'table_base'

# BGP-AS--OSPF-Area table
class ASAreaTable < TableBase
  extend Forwardable

  def_delegators :@records, :each, :find, :[]

  def initialize(target, table_of, debug = false)
    super(target, nil, debug)

    @as_numbers = table_of[:as_numbers]
    @edges_bgp_table = table_of[:edges_bgp]
    @config_ospf_area_table = table_of[:config_ospf_area]

    nodes_in_as = find_nodes_in_as
    debug '# nodes_in_as:', nodes_in_as
    @records = make_as_area_table(nodes_in_as)
  end

  def nodes_in(asn, area)
    @records
      .find_all { |r| r[:as] == asn && r[:area] == area }
      .map { |r| r[:node] }
      .sort
      .uniq
  end

  def areas_in_as(asn)
    @records
      .find_all { |r| r[:as] == asn }
      .map { |r| r[:area] }
      .find_all { |area| area >= 0 } # area 0 MUST be backbone area.
      .sort
      .uniq
  end

  def records_has_area
    @records.select { |r| r[:area] >= 0 }
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

  def find_all_by_as_node(asn, node)
    @records.find_all { |r| r[:as] == asn && r[:node] == node }
  end

  private

  # name of ospf-are node in ospf-area layer
  def area_node_name(asn, area)
    "as#{asn}-area#{area}"
  end

  def area_link_data(area_node_pair, interface, area_tp_count)
    {
      as: area_node_pair[:as],
      node: area_node_pair[:node],
      node_tp: interface[:interface],
      area: area_node_name(area_node_pair[:as], area_node_pair[:area]),
      area_tp: "p#{area_tp_count}"
    }
  end

  def area_node_connections
    inter_area_nodes.map do |as_node|
      find_all_by_as_node(as_node[:as], as_node[:node])
    end
  end

  def inter_area_nodes
    paths = @records.map { |r| "#{r[:as]}__#{r[:node]}" }
    paths
      .sort
      .reject { |p| paths.index(p) == paths.rindex(p) }
      .uniq
      .map do |path|
      path =~ /(.*)__(.*)/
      { as: Regexp.last_match(1).to_i, node: Regexp.last_match(2) }
    end
  end

  def find_nodes_in_as
    nodes_in_as = {}
    @as_numbers.each do |asn|
      edges_in_as = @edges_bgp_table.find_all_by_as(asn)
      # edges (links) is a pair of 2-unidirectional rows for one link
      nodes_in_as[asn] = edges_in_as.map { |e| e.src.node }.sort.uniq
    end
    nodes_in_as
  end

  def make_as_area_table(nodes_in_as)
    as_area_table = []
    nodes_in_as.each_pair do |asn, nodes|
      nodes.each do |node|
        @config_ospf_area_table.find_all_by_node(node).each do |config|
          as_area_table.push(config.as_area(asn))
        end
      end
    end
    as_area_table
  end
end
