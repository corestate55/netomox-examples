# frozen_string_literal: true

require 'forwardable'
require_relative 'config_bgp_proc_core'

# edge (term-point) of inter bgp-proc link
class BGPProcEdge
  attr_accessor :node, :ip, :interface

  def initialize(node, ip, interface)
    @node = node
    @ip = ip
    @interface = interface
  end

  def to_s
    "BGPProcEdge: #{@node},#{@ip},#{@interface}"
  end
end

# row of config_bgp_proc table
class ConfigBGPProcTableRecord < ConfigBGPProcTableRecordCore
  def initialize(record, table_of, debug = false)
    super(record, debug)

    @routes_table = table_of[:routes]
    @ip_owners_table = table_of[:ip_owners]
    @edges_bgp_table = table_of[:edges_bgp]
    @config_bgp_peer_table = table_of[:config_bgp_peer]
  end

  def ips_facing_neighbors
    @neighbors
      .map { |neighbor_ip| @edges_bgp_table.find_edges(@node, neighbor_ip) }
      .delete_if(&:nil?)
      .map { |edge| new_bgp_proc_tp(edge) }
  end

  def bgp_proc_node_attribute
    {
      name: @node,
      router_id: @router_id,
      prefixes: @routes_table.routes_bgp_proc(@node),
      flags: [
        'bgp-proc',
        "confederation=#{confederation_flags}",
        "RR=#{rr_flags}",
        "network=#{@routes_table.find_all_bgp_advertise_network(@node)}"
      ]
    }
  end

  private

  def new_bgp_proc_tp(edge)
    tp = @ip_owners_table.find_interface(@node, edge.src.ip)
    BGPProcEdge.new(@node, edge.src.ip, tp)
  end

  def confederation_flags
    confederation_local_asn = @config_bgp_peer_table.local_asn(@node)
    confederation_asn = @config_bgp_peer_table.confederation_asn(@node)
    return {} if confederation_local_asn.nil? || confederation_asn.nil?

    {
      local_as: confederation_local_asn,
      global_as: confederation_asn
    }
  end

  def rr_flags
    @config_bgp_peer_table.rr_data(@node)
  end
end

# config_bgp_proc table
class ConfigBGPProcTable < ConfigBGPProcTableCore
  extend Forwardable

  def_delegators :@records, :each, :map, :find, :[]

  def initialize(target, table_of, debug = false)
    super(target, debug)

    @records = @orig_table.map do |record|
      ConfigBGPProcTableRecord.new(record, table_of, debug)
    end
  end
end
