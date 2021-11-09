# frozen_string_literal: true

require 'json'
require 'pry'
require_relative 'layer1p'

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
  nws = Netomox::DSL::Networks.new
  layers = [
    # L3DataBuilder.new(target),
    # L2DataBuilder.new(target),
    L1DataBuilder.new(target)
  ]
  nws.networks = layers.map(&:interpret).map(&:networks).flatten
  # binding.pry # debug
  to_json(nws)
end

## TEST
# puts generate_json('sample3')
