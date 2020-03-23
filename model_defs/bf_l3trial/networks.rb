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
  def initialize(target: '', debug: false, csv_dir: '')
    @target = target
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
    nws = Netomox::DSL::Networks.new
    nws.networks = generate_nmx_networks
    sort_node_tp!(nws)
    json_str = JSON.pretty_generate(nws.topo_data)
    shortening_interface_name(json_str)
  end

  def debug_print
    if @layer_table[@debug]
      opts = { target: @target, debug: true, csv_dir: @csv_dir }
      layer = @layer_table[@debug].new(opts)
      layer.dump
      # puts layer.to_json
    else
      warn 'Invalid debug option'
    end
  end

  private

  def generate_nmx_networks
    opts = { target: @target, csv_dir: @csv_dir }
    %i[bgp_as bgp_proc ospf_area ospf_proc l3]
      .map { |l| @layer_table[l].new(opts) }
      .map(&:interpret)
      .map(&:networks)
      .flatten
  end

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
