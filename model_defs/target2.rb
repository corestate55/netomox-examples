# frozen_string_literal: true

require 'json'
require 'netomox'
require 'optparse'
require_relative 'target/layer1'
require_relative 'target/layer15'
require_relative 'target2/layer2'
require_relative 'target2/layer3'

opts = ARGV.getopts('d')
if opts['d']
  puts '[2] L2 Compact Model'
  exit 0
end

nws = Netomox::DSL::Networks.new
register_target_layer3(nws)
register_target_layer2(nws)
register_target_layer15(nws)
register_target_layer1(nws)

puts JSON.pretty_generate(nws.topo_data)
