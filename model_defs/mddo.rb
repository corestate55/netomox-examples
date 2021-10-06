require 'json'
require 'netomox'
require 'optparse'
require_relative 'mddo/layer1'

opts = ARGV.getopts('d')
if opts['d']
  puts 'OOL-MDDO PJ Trial'
  exit 0
end

nws = Netomox::DSL::Networks.new
register_target_layer1(nws)

puts JSON.pretty_generate(nws.topo_data)
