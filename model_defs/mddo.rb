require 'json'
require 'netomox'
require 'optparse'
require_relative 'mddo/layer1'
require_relative 'mddo/layer2'
require_relative 'mddo/layer3'
require_relative 'mddo/bgp-proc'

opts = ARGV.getopts('d')
if opts['d']
  puts 'OOL-MDDO PJ Trial'
  exit 0
end

nws = Netomox::DSL::Networks.new
register_target_layer1(nws)
register_target_layer2(nws)
register_target_layer3(nws)
register_target_bgp_proc(nws)

puts JSON.pretty_generate(nws.topo_data)
