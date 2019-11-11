# frozen_string_literal: true

require 'forwardable'
require_relative './table_base'

# row of layer1-edges table
class EdgesLayer1TableRecord
  attr_accessor :src, :dst

  def initialize(record)
    @src = EdgeBase.new(record[:interface])
    @dst = EdgeBase.new(record[:remote_interface])
  end

  def ==(other)
    @src == other.src && @dst == other.dst
  end
end

# layer1-edges table
class EdgesLayer1Table < TableBase
  extend Forwardable

  def_delegators :@records, :each, :find, :[]

  def initialize(target)
    super(target, 'edges_layer1.csv')
    @records = @orig_table.map { |r| EdgesLayer1TableRecord.new(r) }
  end

  def find_pair(node, interface)
    find_target = EdgeBase.new("#{node}[#{interface}]")
    rec = @records.find { |r| r.src == find_target }
    rec ? rec.dst : rec
  end
end
