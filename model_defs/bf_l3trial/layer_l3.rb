# frozen_string_literal: true

require_relative 'layer_base'
require_relative 'csv/ip_owners_table'
require_relative 'csv/edges_layer3_table'

# layer topology converter for batfish layer3 network data
class Layer3TopologyConverter < TopologyLayerBase
  def initialize(opts = {})
    super(**opts)

    setup_edges_layer3_table
    make_networks
  end

  private

  def setup_edges_layer3_table
    @edges_layer3_table = EdgesL3Table.new(@target)
  end

  def make_l3node_tps(interfaces)
    interfaces.map do |tp|
      ptp = PTermPoint.new(tp.interface)
      ptp.attribute = { ip_addrs: [tp.ip_mask_str] }
      ptp
    end
  end

  def make_l3node(node, interfaces)
    pnode = PNode.new(node)
    prefixes = @routes_table.routes_l3node(node)
    pnode.attribute = { prefixes: prefixes, flags: ['layer3'] }
    pnode.tps = make_l3node_tps(interfaces)
    pnode
  end

  def make_nodes
    @ip_owners_table.node_interfaces_table.each_pair do |node, interfaces|
      @nodes.push(make_l3node(node, interfaces))
    end
    @nodes
  end

  def make_links
    @edges_layer3_table.layer3_links.map do |l3_link|
      add_link l3_link.src.node, l3_link.src.interface,
               l3_link.dst.node, l3_link.dst.interface,
               false
    end
    @links
  end

  def make_networks
    @network = PNetwork.new('layer3')
    @network.type = Netomox::NWTYPE_L3
    @network.nodes = make_nodes
    @network.links = make_links
    @networks.networks.push(@network)
    @networks
  end
end
