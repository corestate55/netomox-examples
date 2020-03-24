# frozen_string_literal: true

require 'forwardable'
require_relative 'p_networks'

# base class for data builder with pseudo networks
class DataBuilderBase
  attr_accessor :networks

  def initialize
    @networks = PNetworks.new # PNetworks
    @nodes = [] # Array of PNodes
    @links = [] # Array of PLinks
  end

  def interpret
    @networks.interpret
  end

  def topo_data
    interpret.topo_data
  end

  def dump
    @networks.dump
  end

  protected

  def find_node(node_name)
    @nodes.find { |n| n.name == node_name }
  end

  def find_or_new_node(node_name)
    find_node(node_name) || PNode.new(node_name)
  end

  def add_link(src_node, src_tp, dst_node, dst_tp, bidirectional = true)
    src = PLinkEdge.new(src_node, src_tp)
    dst = PLinkEdge.new(dst_node, dst_tp)
    @links.push(PLink.new(src, dst))
    @links.push(PLink.new(dst, src)) if bidirectional
  end

  def add_node_if_new(pnode)
    return if find_node(pnode.name)

    @nodes.push(pnode)
  end
end
