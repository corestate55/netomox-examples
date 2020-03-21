# frozen_string_literal: true

require 'forwardable'
require_relative 'config_bgp_proc_core'

# row of config_bgp_proc table
class ConfigBGPProcTableRecord < ConfigBGPProcTableRecordCore
  def initialize(record, table_of, debug = false)
    super(record, debug)

    @routes_table = table_of[:routes]
    @ip_owners_table = table_of[:ip_owners]
    @edges_bgp_table = table_of[:edges_bgp]
  end

  def ips_facing_neighbors
    @neighbors
      .map { |neighbor_ip| @edges_bgp_table.find_edges(@node, neighbor_ip) }
      .delete_if(&:nil?)
      .map { |edge| bgp_proc_tp(edge) }
  end

  def bgp_proc_node_attribute
    {
      name: @node,
      router_id: @router_id,
      prefixes: @routes_table.routes_of(@node, /.*bgp/),
      flags: ['bgp-proc']
    }
  end

  private

  def bgp_proc_tp(edge)
    {
      node: @node,
      ip: edge.src.ip,
      interface: @ip_owners_table.find_interface(@node, edge.src.ip)
    }
  end
end

# config_bgp_proc table
class ConfigBGPProcTable < ConfigBGPProcTableCore
  extend Forwardable

  def_delegators :@records, :each, :find, :[]

  def initialize(target, table_of, debug = false)
    super(target, debug)

    @records = @orig_table.map do |record|
      ConfigBGPProcTableRecord.new(record, table_of, debug)
    end
  end
end
