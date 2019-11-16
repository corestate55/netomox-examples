# frozen_string_literal: true

require 'forwardable'
require_relative 'table_base'

# nodes in L3 segment
class L3Node < EdgeBase
  attr_accessor :node, :vlan_id

  # node: EdgeBase obj
  def initialize(vlan_id, node)
    @node = node.node
    @interface = node.interface
    @vlan_id = vlan_id
  end

  def to_s
    "VL#{@vlan_id}: #{@node}[#{@interface}]"
  end
end

# L3segment
class L3Segment
  attr_accessor :nodes

  def initialize
    @nodes = []
  end

  def add_node(vlan_id, node)
    @nodes.push(L3Node.new(vlan_id, node))
  end

  def dump
    @nodes.each do |node|
      warn "  # node: #{node}"
    end
  end

  def vlans
    @nodes.map(&:vlan_id).sort.uniq
  end

  def find_node_int(node, interface)
    @nodes.find { |n| n.node == node && n.interface == interface }
  end
end

# Layer3 segment table
class L3SegmentsTable
  extend Forwardable

  def_delegators :@records, :each, :each_pair, :find, :[]

  def initialize
    @records = {}
  end

  def add_segment(seg_name)
    @records[seg_name] = L3Segment.new
  end

  def segments
    @records.keys
  end

  def dump
    @records.each_pair do |seg_name, seg|
      warn "# seg_name: #{seg_name}"
      seg.dump
    end
  end

  def seg_name_owns(node, interface)
    segments.find do |seg_name|
      @records[seg_name].find_node_int(node, interface)
    end
  end
end
