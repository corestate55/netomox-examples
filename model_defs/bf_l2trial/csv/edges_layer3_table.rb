# frozen_string_literal: true

require 'forwardable'
require_relative 'table_base'

# endpoint of layer3-edge
class EdgeLayer3 < EdgeBase
  attr_accessor :ips

  # rubocop:disable Security/Eval
  def initialize(interface_str, ips_str)
    super(interface_str)
    @ips = eval(ips_str) # string 2 array
  end
  # rubocop:enable Security/Eval

  def to_s
    "#{@node}[#{@interface}]#{@ips}"
  end

  # reverse function of #to_s
  def self.new_from_str(str)
    str =~ /(.+\[.+\])(.+)/
    EdgeLayer3.new(Regexp.last_match(1), Regexp.last_match(2))
  end
end

# row of layer3-edges table
class EdgesLayer3TableRecord < TableRecordBase
  attr_accessor :src, :dst

  def initialize(record)
    @src = EdgeLayer3.new(record[:interface], record[:ips])
    @dst = EdgeLayer3.new(record[:remote_interface], record[:remote_ips])
  end
end

# llayer3-edges tablef
class EdgesLayer3Table < TableBase
  extend Forwardable

  def_delegators :@records, :each, :find, :[]

  def initialize(target)
    super(target, 'edges_layer3.csv')
    @records = @orig_table.map { |r| EdgesLayer3TableRecord.new(r) }
  end
end
