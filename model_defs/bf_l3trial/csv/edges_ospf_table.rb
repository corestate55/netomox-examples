# frozen_string_literal: true

require 'forwardable'
require_relative 'table_base'

# edge (term-point) of inter ospf-proc link.
class OSPFEdge
  attr_accessor :node, :interface, :as, :area
  def initialize(node_interface, as_area_table)
    @as_area_table = as_area_table
    @node, @interface = split_node_interface(node_interface)
    @as, @area = term_point_info
  end

  private

  def term_point_info
    found_row = @as_area_table.find do |row|
      row[:node] == @node && interface_names(row).include?(@interface)
    end
    if found_row
      [found_row[:as], found_row[:area]]
    else
      [-1, -1]
    end
  end

  def interface_names(as_area_row)
    as_area_row[:interfaces].map { |if_info| if_info[:interface] }
  end

  def split_node_interface(node_interface)
    /(.+)\[(.+)\]/.match(node_interface).captures
  end
end

# row of edges_ospf table
class EdgesOSPFTableRecord < TableRecordBase
  attr_accessor :src, :dst

  def initialize(record, table_of, debug = false)
    super(debug)

    @src = OSPFEdge.new(record[:interface], table_of[:as_area])
    @dst = OSPFEdge.new(record[:remote_interface], table_of[:as_area])
  end
end

# ospf_edges table (ospf_proc link)
class EdgesOSPFTable < TableBase
  extend Forwardable

  def_delegators :@records, :each, :find, :[]

  def initialize(target, as_area_table, debug = false)
    super(target, 'edges_ospf.csv', debug)

    @records = @orig_table.map do |row|
      EdgesOSPFTableRecord.new(row, as_area_table, debug)
    end
  end

  def proc_links
    @records.filter do |rec|
      rec.src.as >= 0 && rec.dst.as >= 0
    end
  end
end
