require 'json'
require 'netomox'
require_relative 'target/layer1'
require_relative 'target/layer15'
require_relative 'target3/layer2'
require_relative 'target3/layer3'

nws = Netomox::DSL::Networks.new
register_target_layer3(nws)
register_target_layer2(nws)
register_target_layer15(nws)
register_target_layer1(nws)

puts JSON.pretty_generate(nws.topo_data)
