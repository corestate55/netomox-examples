#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative './topo2config_converter_base'

# data converter (layer3 to tinet)
class Topo2Layer3ConfigConverter < Topo2ConfigConverterBase
  def initialize(file)
    super(file)
    construct_l3_config
  end

  private

  def construct_l3_config
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
  def initialize(file)
    super(file)
    construct_ospf_config
  end

  private

  def construct_ospf_config
    # TBA
  end
end

# exec:
# hagiwara@dev02:~/nwmodel/netomox-examples$ bundle exec ruby config_defs/topo2config_converter.rb
file_dir = Pathname.new('~/nwmodel/netomox-examples/netoviz/static/model')
file_name = Pathname.new('bf_l3s1.json')
file_path = file_dir.join(file_name).expand_path
# config_converter = Topo2Layer3ConfigConverter.new(file_path)
config_converter = Topo2OSPFConfigConverter.new(file_path)
puts config_converter.to_config
