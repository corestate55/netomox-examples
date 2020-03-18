# frozen_string_literal: true

require 'json'
require 'netomox'
require_relative 'layer_bgp_as'
require_relative 'layer_bgp_proc'
require_relative 'layer_ospf_area'
require_relative 'layer_ospf_proc'
require_relative 'layer_l3'

# common batfish-l3 topology(networks) class
class BFL3Networks
  def initialize(debug: false, csv_dir: '')
    @debug = debug
    @csv_dir = csv_dir
    @layer_table = {
      bgp_as: BGPASTopologyConverter,
      bgp_proc: BGPProcTopologyConverter,
      ospf_area: OSPFAreaTopologyConverter,
      ospf_proc: OSPFProcTopologyConverter,
      l3: Layer3TopologyConverter
    }
  end

  def integrate
    layer_seq = %i[bgp_as bgp_proc ospf_area ospf_proc l3]
    nws = Netomox::DSL::Networks.new
    layer_seq.each do |layer|
      layer = @layer_table[layer].new(csv_dir: @csv_dir)
      layer.make_topology(nws)
    end
    sort_node_tp!(nws)
    json_str = JSON.pretty_generate(nws.topo_data)
    shortening_interface_name(json_str)
  end

  def debug_print
    if @layer_table[@debug]
      layer = @layer_table[@debug].new(debug: true, csv_dir: @csv_dir)
      puts layer.to_json
    else
      warn 'Invalid debug option'
    end
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
