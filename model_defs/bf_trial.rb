# frozen_string_literal: true

require 'json'
require 'netomox'
require 'optparse'
require_relative 'bf_trial/layer_bgp'
require_relative 'bf_trial/layer_ospf'
require_relative 'bf_trial/layer_l3'

# usage:
#   bundle exec ruby THIS.rb --debug=[bgp|ospf|l3]
# with bundle exec, ARGV[0] is not THIS script name.

opts = ARGV.getopts('d', 'debug:')
if opts['d']
  puts 'batfish trial'
  exit 0
end

debug = opts['debug'] ? opts['debug'].intern : nil

if debug == :bgp
  layer_bgp = BGPTopologyConverter.new(debug: true)
  layer_bgp.puts_json
end
if debug == :ospf
  layer_ospf = OSPFTopologyConverter.new(debug: true)
  layer_ospf.puts_json
end
if debug == :l3
  layer_l3 = Layer3TopologyConverter.new(debug: true)
  layer_l3.puts_json
end

exit 0 unless debug.nil?

def shortening_interface_name(str)
  str
    .gsub(/GigabitEthernet/, 'Gi')
    .gsub!(/Loopback/, 'Lo')
end

def sort_node_tp!(nws)
  nws.networks.each { |network| network.nodes.each(&:sort_tp_by_name!) }
  nws.networks.each(&:sort_node_by_name!)
end

# integrate
layer_bgp = BGPTopologyConverter.new
layer_ospf = OSPFTopologyConverter.new
layer_l3 = Layer3TopologyConverter.new

nws = Netomox::DSL::Networks.new
layer_bgp.make_topology(nws)
layer_ospf.make_topology(nws)
layer_l3.make_topology(nws)
sort_node_tp!(nws)
puts shortening_interface_name(JSON.pretty_generate(nws.topo_data))
