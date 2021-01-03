#!/usr/bin/env ruby
# frozen_string_literal: true

require 'optparse'
require_relative './topo2config_converter_base'
require_relative './tinet_config_ospf'

# data converter (layer3 to tinet)
class Topo2Layer3ConfigConverter < Topo2ConfigConverterBase
  def initialize(opts)
    super(opts)
    construct_layer3_config
  end

  private

  def construct_layer3_config
    l3_nw = @networks.find_network('layer3')
    l3_nw.nodes.each do |node|
      @tinet_config.add_l3_node(l3_nw, node)
      @tinet_config.add_l3_node_config(node)
      @tinet_config.add_l3_test(l3_nw, node)
    end
  end
end

# data converter (ospf)
class Topo2OSPFConfigConverter < Topo2Layer3ConfigConverter
  def initialize(opts)
    super(opts)
    construct_ospf_config
  end

  private

  def construct_ospf_config
    ospf_proc_nw = @networks.find_network('ospf-proc')
    ospf_proc_nw.nodes.each do |node|
      @tinet_config.add_ospf_node_config(node)
    end
  end
end

# exec:
# hagiwara@dev02:~/nwmodel/netomox-examples$ bundle exec ruby config_defs/topo2config_converter.rb

opts = ARGV.getopts('', 'debug:')

debug = opts['debug'] ? opts['debug'].intern : nil

file_dir = Pathname.new('~/nwmodel/netomox-examples/netoviz/static/model')
file_name = Pathname.new('bf_l3s1.json')
file_path = file_dir.join(file_name).expand_path

opts = { file: file_path, debug: debug }
config_converter = if debug == :layer3
                     opts[:tinet_config] = TinetConfigLayer3.new
                     Topo2Layer3ConfigConverter.new(opts)
                   else
                     opts[:tinet_config] = TinetConfigOSPF.new
                     Topo2OSPFConfigConverter.new(opts)
                   end
puts config_converter.to_config
