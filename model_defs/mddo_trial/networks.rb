# frozen_string_literal: true

require 'json'
require 'pry'
require_relative 'layer1p'
require_relative 'layer2p'

def to_json(nws)
  JSON.pretty_generate(nws.topo_data)
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
end

def generate_json(target)
  l1_builder = L1DataBuilder.new(target)
  layer1p = l1_builder.make_networks

  l2_builder = L2DataBuilder.new(target, layer1p.find_network_by_name('layer1'))
  layer2p = l2_builder.make_networks

  nws = Netomox::DSL::Networks.new
  nws.networks = [layer1p, layer2p].map(&:interpret).map(&:networks).flatten
  # binding.pry # debug
  to_json(nws)
end

## TEST
# puts generate_json('sample3')
