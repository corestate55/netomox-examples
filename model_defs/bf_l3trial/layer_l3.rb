# frozen_string_literal: true

require 'csv'
require 'netomox'
require_relative 'layer_base'
require_relative 'csv/ip_owners_table'
require_relative 'csv/edges_layer3_table'

# layer topology converter for batfish layer3 network data
class Layer3TopologyConverter < TopologyLayerBase
  def initialize(opts = {})
    super(opts)

    @edges_layer3_table = EdgesL3Table.new(@target)
  end

  def make_topology(nws)
    make_layer3_layer(nws)
  end

  private

  # rubocop:disable Metrics/MethodLength
  def make_layer3_layer_nodes(nws)
    @ip_owners_table.node_interfaces_table.each_pair do |node, interfaces|
      # prefixes: exclude bgp,ospf (only connected)
      prefixes = @routes_table.routes_of(node, /^(?!.*(bgp|ospf)).+$/)
      nws.network('layer3').register do
        node node do
          interfaces.each do |tp|
            term_point tp[:interface] do
              attribute(ip_addrs: ["#{tp[:ip]}/#{tp[:mask]}"])
            end
          end
          attribute(prefixes: prefixes, flags: ['layer3'])
        end
      end
    end
  end
  # rubocop:enable Metrics/MethodLength

  def make_layer3_layer_links(nws)
    @edges_layer3_table.layer3_links.each do |l3_link|
      nws.network('layer3').register do
        link l3_link.src.node, l3_link.src.interface,
             l3_link.dst.node, l3_link.dst.interface
      end
    end
  end

  def make_layer3_layer(nws)
    nws.register do
      network 'layer3' do
        type Netomox::NWTYPE_L3
      end
    end
    make_layer3_layer_nodes(nws)
    make_layer3_layer_links(nws)
  end
end
