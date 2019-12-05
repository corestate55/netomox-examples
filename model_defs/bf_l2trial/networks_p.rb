# frozen_string_literal: true

require 'json'
require 'pry'
require_relative 'layer3p'
require_relative 'layer2p'
require_relative 'layer1p'

def shortening_interface_name(str)
  str.gsub!(/GigabitEthernet/, 'Gi') if str =~ /GigabitEthernet/
  str.gsub!(/Port-Channel/, 'Po') if str =~ /Port-Channel/
  str
end

def print_nws(nws)
  json_str = JSON.pretty_generate(nws.topo_data)
  puts shortening_interface_name(json_str)
end

def dump(target, layer)
  layer_p = case layer
        when /l(?:ayer)?1/i
          L1DataBuilder.new(target)
        when /l(?:ayer)?2/i
          L2DataBuilder.new(target)
        when /l(?:ayer)?3/i
          L3DataBuilder.new(target)
        end
  layer_p.dump
  nws = Netomox::DSL::Networks.new
  nws.networks = layer_p.interpret.networks
  print_nws(nws)
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
  print_nws(nws)
end

## TEST
# puts generate_json('sample3')
