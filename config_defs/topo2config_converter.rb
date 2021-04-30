#!/usr/bin/env ruby
# frozen_string_literal: true

require 'optparse'
require_relative './topo2config_converter_base'
require_relative './tinet_config_ospf'
require_relative './tinet_config_bgp'

# whole layers
class TinetConfigAll < TinetConfigLayer3
  include TinetConfigOSPFModule
  include TinetConfigBGPModule
end

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
      @tinet_config.add_ospf_test(node)
    end
  end
end

# data converter (bgp)
class Topo2BGPConfigConverter < Topo2Layer3ConfigConverter
  def initialize(opts)
    super(opts)
    construct_bgp_config
  end

  private

  def construct_bgp_config
    bgp_as_nw = @networks.find_network('bgp-as')
    bgp_proc_nw = @networks.find_network('bgp-proc')
    @tinet_config.add_bgp_node_config_by_nw(bgp_as_nw, bgp_proc_nw)
  end
end

# data converter (whole layers)
class Topo2AllConfigConverter < Topo2Layer3ConfigConverter
  def initialize(opts)
    super(opts)
    construct_all_config
  end

  private

  def construct_all_config
    # ospf
    ospf_proc_nw = @networks.find_network('ospf-proc')
    ospf_proc_nw.nodes.each do |node|
      @tinet_config.add_ospf_node_config(node)
      @tinet_config.add_ospf_test(node)
    end

    # bgp
    bgp_as_nw = @networks.find_network('bgp-as')
    bgp_proc_nw = @networks.find_network('bgp-proc')
    @tinet_config.add_bgp_node_config_by_nw(bgp_as_nw, bgp_proc_nw)
  end
end

# exec:
# hagiwara@dev02:~/nwmodel/netomox-examples$ bundle exec ruby config_defs/topo2config_converter.rb

# rubocop:disable Metrics/MethodLength
def config_converter(opts)
  case opts[:debug]
  when :bgp
    opts[:tinet_config] = TinetConfigBGP.new
    Topo2BGPConfigConverter.new(opts)
  when :ospf
    opts[:tinet_config] = TinetConfigOSPF.new
    Topo2OSPFConfigConverter.new(opts)
  when :l3, :layer3
    opts[:tinet_config] = TinetConfigLayer3.new
    Topo2Layer3ConfigConverter.new(opts)
  else
    # default (also :all)
    opts[:tinet_config] = TinetConfigAll.new
    Topo2AllConfigConverter.new(opts)
  end
end
# rubocop:enable Metrics/MethodLength

opts = ARGV.getopts('', 'debug:')

opt_debug = opts['debug'] ? opts['debug'].intern : nil
acceptable_opts = %i[all l3 layer3 ospf bgp] # all: default
if opt_debug && !acceptable_opts.include?(opt_debug)
  warn "Unknown debug option: #{opt_debug}"
  exit 1
end
warn "# Debug mode : #{opt_debug}" if opt_debug
opts['debug'] = opt_debug

file_dir = Pathname.new('~/nwmodel/netomox-examples/netoviz/static/model')
file_name = Pathname.new('bf_l3s1.json')
file_path = file_dir.join(file_name).expand_path

opts = { file: file_path, debug: opt_debug }
config_converter = config_converter(opts)
puts config_converter.to_config
