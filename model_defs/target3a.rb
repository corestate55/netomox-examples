# frozen_string_literal: true

require 'json'
require 'netomox'
require 'optparse'
require_relative 'target3a/layer1'
require_relative 'target3a/layer15'
require_relative 'target3a/layer2'
require_relative 'target3a/layer3'
require_relative 'target3a/layer35'

opts = ARGV.getopts('d')
if opts['d']
  puts '[3a] L2 Aggr and L3.5'
  exit 0
end

nws = Netomox::DSL::Networks.new
register_target_layer35(nws)
register_target_layer3(nws)
register_target_layer2(nws)
register_target_layer15(nws)
register_target_layer1(nws)

puts JSON.pretty_generate(nws.topo_data)
