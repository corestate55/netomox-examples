# frozen_string_literal: true

require 'forwardable'
require_relative 'table_base'

# record of nodes_in_as table
class NodesInASTableRecord < TableRecordBase
  extend Forwardable

  def_delegators :@nodes, :each, :find, :[]

  def initialize(asn, nodes, table_of, debug = false)
    super(debug)

    @config_ospf_area_table = table_of[:config_ospf_area]
    @config_bgp_proc_table = table_of[:config_bgp_proc]

    @as = asn
    @nodes = nodes # Array of node (string)
  end

  def inter_area_routers
    @nodes
      .map { |n| @config_ospf_area_table.area_border_data(@as, n) }
      .filter { |r| r[:areas].length > 1 } # routers connect multiple areas.
  end

  def find_areas
    @nodes
      .map { |n| @config_ospf_area_table.find_all_area_of(n) }
      .flatten
      .sort.uniq
  end

  def router_ids
    @nodes.map { |n| @config_bgp_proc_table.find_router_id(n) }
  end

  def to_s
    "NodesInASTableRec: #{@nodes}"
  end
end

# Nodes in BGP-AS table (for bgp-* topology)
class NodesInASTable < TableBase
  extend Forwardable

  def_delegators :@records, :each, :find, :[]

  def initialize(target, table_of, debug = false)
    super(target, nil, debug)

    # NOTICE: @records is not Array, it is Hash
    # key:ASN => value:nodes (Array of String)
    @records = make_nodes_in_as(table_of)
  end

  # generate areas_in_as table
  def make_areas_in_as
    areas_in_as = {}
    @records.each_pair do |asn, rec|
      areas_in_as[asn] = rec.find_areas
    end
    areas_in_as
  end

  def to_s
    @records
      .map { |as, rec| "NodesInASTable: #{as}->#{rec}" }
      .join("\n")
      .to_s
  end

  private

  def make_nodes_in_as(table_of)
    nodes_in_as = {}
    table_of[:as_numbers].each do |asn|
      nodes = table_of[:edges_bgp].nodes_in(asn)
      nodes_in_as[asn] = NodesInASTableRecord.new(asn, nodes, table_of, @debug)
    end
    nodes_in_as
  end
end
