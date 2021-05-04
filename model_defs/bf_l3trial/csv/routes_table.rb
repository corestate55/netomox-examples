# frozen_string_literal: true

require 'forwardable'
require_relative 'table_base'

# row of routes table
class RoutesTableRecord < TableRecordBase
  attr_accessor :node, :protocol, :network, :metric, :next_hop_ip, :next_hop_interface

  def initialize(record, debug = false)
    super(debug)

    @node = record[:node]
    @protocol = record[:protocol]
    @network = record[:network]
    @metric = record[:metric]
    @next_hop_ip = record[:next_hop_ip]
    @next_hop_interface = record[:next_hop_interface]
  end
end

# routes table
class RoutesTable < TableBase
  extend Forwardable

  def_delegators :@records, :each, :find, :[]

  def initialize(target, debug = false)
    super(target, 'routes.csv', debug)

    @records = @orig_table.map { |r| RoutesTableRecord.new(r, debug) }
  end

  def routes_l3node(node)
    routes_of(node, /^(?!.*(bgp|ospf)).+$/)
  end

  def routes_ospf_proc(node)
    routes_of(node, /ospf.*/)
  end

  def routes_bgp_proc(node)
    [
      routes_of(node, /.*bgp/),
      find_all_bgp_advertise_network(node).map { |row| prefix_attr(row.network, row.metric, row.protocol) }
    ].flatten
  end

  def bgp_advertise_networks(node)
    found_networks = find_all_bgp_advertise_network(node)
    return [] if found_networks.empty?

    found_networks.map(&:network)
  end

  def find_all_bgp_advertise_network(node)
    # batfish bgp-related-query cannot pick up
    # bgp `network` command info (what network is advertised).
    # but it appears in answer of `routes` query as static-route
    # (it is static and doesn't have next-hop)
    @records.find_all do |row|
      row.node == node && row.protocol == 'static' &&
        row.next_hop_ip == 'AUTO/NONE(-1l)' &&
        row.next_hop_interface == 'null_interface'
    end
  end

  private

  def routes_of(node, protocol = /.+/)
    @records
      .find_all { |row| row.node == node && row.protocol =~ protocol }
      .map { |row| prefix_attr(row.network, row.metric, row.protocol) }
  end

  def prefix_attr(prefix, metric, protocol)
    { prefix: prefix, metric: metric, flag: [protocol] }
  end
end
