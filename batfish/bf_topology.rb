require 'json'
require 'netomox'
require_relative 'layer_bgp'
require_relative 'layer_ospf'
require_relative 'layer_3'


layer_bgp = BGPTopologyConverter.new
layer_ospf = OSPFTopologyConverter.new
layer_3 = Layer3TopologyConverter.new

nws = Netomox::DSL::Networks.new
layer_bgp.make_topology(nws)
layer_ospf.make_topology(nws)
layer_3.make_topology(nws)
puts JSON.pretty_generate(nws.topo_data)
