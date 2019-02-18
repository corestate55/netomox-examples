require 'json'
require 'netomox'
require_relative 'target3a/layer1'
require_relative 'target3a/layer15'
require_relative 'target3b/layer2a'
require_relative 'target3b/layer2b'
require_relative 'target3b/layer3'
require_relative 'target3a/layer35'

nws = Netomox::DSL::Networks.new
register_target_layer1(nws)
register_target_layer15(nws)
register_target_layer2a(nws)
register_target_layer2b(nws)
register_target_layer3(nws)
register_target_layer35(nws)

puts JSON.pretty_generate(nws.topo_data)
