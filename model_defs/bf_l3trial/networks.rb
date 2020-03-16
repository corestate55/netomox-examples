# frozen_string_literal: true

require 'json'
require 'netomox'
require_relative 'layer_bgp'
require_relative 'layer_ospf'
require_relative 'layer_l3'

# common batfish-l3 topology(networks) class
class BFL3Networks
  def initialize(debug: false, csv_dir: '')
    @debug = debug
    @csv_dir = csv_dir
  end

  def integrate
    layer_bgp = BGPTopologyConverter.new(csv_dir: @csv_dir)
    layer_ospf = OSPFTopologyConverter.new(csv_dir: @csv_dir)
    layer_l3 = Layer3TopologyConverter.new(csv_dir: @csv_dir)

    nws = Netomox::DSL::Networks.new
    layer_bgp.make_topology(nws)
    layer_ospf.make_topology(nws)
    layer_l3.make_topology(nws)
    sort_node_tp!(nws)
    json_str = JSON.pretty_generate(nws.topo_data)
    shortening_interface_name(json_str)
  end

  def debug_print
    layer = case @debug
            when :bgp
              BGPTopologyConverter.new(debug: true, csv_dir: @csv_dir)
            when :ospf
              OSPFTopologyConverter.new(debug: true, csv_dir: @csv_dir)
            when :l3
              Layer3TopologyConverter.new(debug: true, csv_dir: @csv_dir)
            end
    puts layer.nil? ? 'Invalid debug option' : layer.to_json
  end

  private

  def shortening_interface_name(str)
    str.gsub!(/FastEthernet/, 'Fa')
    str.gsub!(/GigabitEthernet/, 'Gi')
    str.gsub!(/Loopback/, 'Lo')
    str
  end

  def sort_node_tp!(nws)
    nws.networks.each { |network| network.nodes.each(&:sort_tp_by_name!) }
    nws.networks.each(&:sort_node_by_name!)
  end
end
