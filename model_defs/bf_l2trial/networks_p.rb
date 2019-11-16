# frozen_string_literal: true

require 'json'
require 'pry'
require_relative 'layer3p'
require_relative 'layer2p'
require_relative 'layer1p'

def shortening_interface_name(str)
  str
    .gsub!(/GigabitEthernet/, 'Gi')
    .gsub!(/Port-Channel/, 'Po')
  str
end

def generate_json(target)
  nws = Netomox::DSL::Networks.new
  layers = [
    L3DataBuilder.new(target),
    L2DataBuilder.new(target),
    L1DataBuilder.new(target)
  ]
  nws.networks = layers.map(&:interpret).map(&:networks).flatten
  # binding.pry # debug

  json_str = JSON.pretty_generate(nws.topo_data)
  shortening_interface_name(json_str)
end

## TEST
# puts generate_json('sample3')
