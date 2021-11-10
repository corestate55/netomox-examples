require 'json'
require 'netomox'
require 'optparse'
require_relative 'mddo/layer1'
require_relative 'mddo/layer15'
require_relative 'mddo/layer2'
require_relative 'mddo/layer3'
require_relative 'mddo/ospf-proc'
require_relative 'mddo/bgp-proc'
require_relative 'mddo/region'

opts = ARGV.getopts('d')
if opts['d']
  puts 'OOL-MDDO PJ Trial 1'
  exit 0
end

nws = Netomox::DSL::Networks.new
register_target_layer1(nws)
register_target_layer15(nws)
register_target_layer2(nws)
register_target_layer3(nws)
register_target_ospf_proc(nws)
register_target_bgp_proc(nws)
register_target_region(nws)

puts JSON.pretty_generate(nws.topo_data)
