# frozen_string_literal: true

require 'csv'
require_relative 'layer_base'

# layer topology converter for batfish bgp network data
class BGPTopologyConverterBase < TopologyLayerBase
  def initialize(opts = {})
    super(opts)
    @edges_bgp_table = read_table('edges_bgp.csv')
    @config_bgp_proc_table = read_table('config_bgp_proc.csv')
  end

  def make_topology(_nws)
    raise 'Abstract method must be override.'
  end

  private

  def make_tables
    @as_numbers = @edges_bgp_table[:as_number].uniq
    debug '# as_numbers: ', @as_numbers
    @nodes_in_as = make_nodes_in_as
    debug '# nodes_in_as: ', @nodes_in_as
  end

  def find_router_id(node)
    data = @config_bgp_proc_table.find { |row| row[:node] == node }
    # NOTICE: assume single process in node
    #   bgp_proc_table has only "neighbor ip list" (destination ip list)
    data[:router_id]
  end

  def find_nodes_in(asn)
    @edges_bgp_table
      .find_all { |row| row[:as_number] == asn }
      .map { |row| row[:node] }
      .sort.uniq
  end

  def make_nodes_in_as
    nodes_in_as = {}
    @as_numbers.each do |asn|
      nodes_in_as[asn] = find_nodes_in(asn)
    end
    nodes_in_as
  end
end
