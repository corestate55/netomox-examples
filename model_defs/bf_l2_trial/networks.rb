# frozen_string_literal: true

require 'json'
require 'netomox'
require_relative 'layer3'
require_relative 'layer2'
require_relative 'layer1'

def shortening_interface_name(str)
  str
    .gsub!(/GigabitEthernet/, 'Gi')
    .gsub!(/Port-Channel/, 'Po')
  str
end

def generate_json(target)
  nws = Netomox::DSL::Networks.new
  register_bfl2_layer3(nws, target)
  register_bfl2_layer2(nws, target)
  register_bfl2_layer1(nws, target)

  json_str = JSON.pretty_generate(nws.topo_data)
  shortening_interface_name(json_str)
end

# puts generate_json('sample3')
