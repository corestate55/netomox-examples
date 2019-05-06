require 'json'
require 'netomox'
require_relative 'layer_bgp'
require_relative 'layer_ospf'
require_relative 'layer_3'

# usage:
#   bundle exec ruby THIS.rb [bgp|ospf|l3]
# with bundle exec, ARGV[0] is not THIS script name.

debug = nil
debug = ARGV[0].downcase.to_sym if ARGV[0]

if debug == :bgp
  layer_bgp = BGPTopologyConverter.new(debug: true)
  layer_bgp.puts_json
end
if debug == :ospf
  layer_ospf = OSPFTopologyConverter.new(debug: true)
  layer_ospf.puts_json
end
if debug == :l3
  layer_3 = Layer3TopologyConverter.new(debug: true)
  layer_3.puts_json
end

exit 0 unless debug.nil?

def shortening_interface_name(str)
  str
    .gsub(/GigabitEthernet/, 'Gi')
    .gsub!(/Loopback/, 'Lo')
end

# integrate
layer_bgp = BGPTopologyConverter.new
layer_ospf = OSPFTopologyConverter.new
layer_3 = Layer3TopologyConverter.new

nws = Netomox::DSL::Networks.new
layer_bgp.make_topology(nws)
layer_ospf.make_topology(nws)
layer_3.make_topology(nws)
puts shortening_interface_name(JSON.pretty_generate(nws.topo_data))
