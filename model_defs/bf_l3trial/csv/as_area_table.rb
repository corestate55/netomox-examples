# frozen_string_literal: true

require 'forwardable'
require_relative 'table_base'
require_relative 'as_area_util'
require_relative 'as_area_links_table'

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

    # NOTICE: @records is NOT array, it is Hash
    # key:AS-Number => value:ASAreaTableRecord
    @records = make_as_area_table(nodes_in_as)
  end

  def nodes_in(asn, area)
    @records
      .find_all { |r| r.as == asn && r.area == area }
      .map(&:node)
      .sort
      .uniq
  end

  def areas_in_as(asn)
    @records
      .find_all { |r| r.as == asn }
      .map(&:area)
      .find_all { |area| area >= 0 } # area 0 MUST be backbone area.
      .sort
      .uniq
  end

  def records_has_area
    @records.select { |r| r.area >= 0 }
  end

  def make_ospf_area_links
    # find router and its interface that connects multiple-area
    area_node_pairs = area_node_connections
    links = area_node_pairs.flatten.map do |pair|
      pair.interfaces.map do |interface|
        ASAreaLink.new(pair.as, pair.area, pair.node, interface.interface)
      end
    end
    links.flatten
  end

  def find_all_by_as_node(asn, node)
    @records.find_all { |r| r.as == asn && r.node == node }
  end

  def to_s
    @records.map(&:to_s).join("\n").to_s
  end

  private

  def area_node_connections
    inter_area_nodes.map do |as_node|
      find_all_by_as_node(as_node[:as], as_node[:node])
    end
  end

  def node_pair_path(node1, node2)
    "#{node1}__#{node2}"
  end

  def select_duplicated_paths
    paths = @records.map { |r| node_pair_path(r.as, r.node) }
    paths
      .sort
      .reject { |p| paths.index(p) == paths.rindex(p) } # reject single element
      .uniq
  end

  def split_node_pair_path(as_node_path)
    /(.*)__(.*)/.match(as_node_path).captures
  end

  def inter_area_nodes
    select_duplicated_paths.map do |as_node_path|
      as, node = split_node_pair_path(as_node_path)
      { as: as.to_i, node: node }
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
        @config_ospf_area_table.find_all_by_node(node).each do |record|
          as_area_table.push(record.as_area(asn))
        end
      end
    end
    as_area_table
  end
end
