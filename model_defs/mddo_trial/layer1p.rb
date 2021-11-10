# frozen_string_literal: true

require 'json'
require_relative '../bf_common/pseudo_model'
require_relative 'csv/node_props_table'
require_relative 'csv/edges_layer1_table'

# L1 data builder
class L1DataBuilder < DataBuilderBase
  def initialize(target)
    super()
    @node_props = NodePropsTable.new(target)
    @l1_edges = EdgesLayer1Table.new(target)
  end

  def make_networks
    @network = PNetwork.new('layer1')
    @network.nodes = make_nodes
    @network.links = make_links
    @networks.push(@network)
    @networks
  end

  private

  def make_node_tps(node_prop)
    node_prop.physical_interfaces.map { |intf| PTermPoint.new(intf) }
  end

  def make_nodes
    @node_props.each do |node_prop|
      pnode = PNode.new(node_prop.node)
      pnode.tps = make_node_tps(node_prop)
      @nodes.push(pnode)
    end
    @nodes
  end

  def make_links
    @l1_edges.each do |edge|
      add_link(edge.src.node, edge.src.interface,
               edge.dst.node, edge.dst.interface, false)
    end
    @links
  end
end

## TEST
# l1db = L1DataBuilder.new('sample3')
# l1db.dump
# puts JSON.pretty_generate(l1db.topo_data)
