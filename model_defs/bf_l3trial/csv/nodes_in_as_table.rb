# frozen_string_literal: true

require 'forwardable'
require_relative 'table_base'

# Nodes in BGP-AS table (for bgp-* topology)
class NodesInASTable < TableBase
  extend Forwardable

  def_delegators :@records, :each, :find, :[]

  def initialize(target, table_of, debug = false)
    super(target, nil, debug)

    @edges_bgp_table = table_of[:edges_bgp]
    @as_numbers = table_of[:as_numbers]
    @config_bgp_proc_table = table_of[:config_bgp_proc]
    @config_ospf_area_table = table_of[:config_ospf_area]

    @records = make_nodes_in_as
  end

  def router_ids_in_as(asn)
    @records[asn].map { |node| @config_bgp_proc_table.find_router_id(node) }
  end

  # generate areas_in_as table
  def make_areas_in_as
    areas_in_as = {}
    @records.each_pair do |asn, nodes|
      areas_in_as[asn] = find_areas(nodes)
    end
    areas_in_as
  end

  private

  def find_areas(nodes)
    areas = nodes.map do |node|
      @config_ospf_area_table.find_all_area_of(node)
    end
    areas.flatten.sort.uniq
  end

  def make_nodes_in_as
    nodes_in_as = {}
    @as_numbers.each do |asn|
      nodes_in_as[asn] = @edges_bgp_table.nodes_in(asn)
    end
    nodes_in_as
  end
end
