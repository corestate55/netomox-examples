# frozen_string_literal: true

require 'forwardable'
require_relative 'table_base'

# edge (term-point) of inter layer3-nodes link.
class L3Edge
  attr_accessor :node, :interface, :ips
  # rubocop:disable Security/Eval
  def initialize(node_interface, ips)
    @node, @interface = split_node_interface(node_interface)
    @ips = eval(ips) # ip list
  end
  # rubocop:enable Security/Eval

  private

  def split_node_interface(node_interface)
    /(.+)\[(.+)\]/.match(node_interface).captures
  end
end

# row of edges_l3 table
class EdgesL3TableRecord < TableRecordBase
  attr_accessor :src, :dst

  def initialize(record, debug)
    super(debug)

    @src = L3Edge.new(record[:interface], record[:ips])
    @dst = L3Edge.new(record[:remote_interface], record[:remote_ips])
  end
end

# edges_l3 table
class EdgesL3Table < TableBase
  extend Forwardable

  def_delegators :@records, :each, :find, :[]

  def initialize(target, debug = false)
    super(target, 'edges_layer3.csv', debug)

    @records = @orig_table.map { |r| EdgesL3TableRecord.new(r, debug) }
  end

  # layer3 links
  def links
    @records.map { |r| { source: r.src, destination: r.dst } }
  end
end
