#!/usr/bin/env ruby
# frozen_string_literal: true

require 'optparse'
require_relative 'topo2config_converter'

def config_converter(opts)
  case opts[:debug]
  when :bgp
    Topo2BGPConfigConverter.new(opts)
  when :ospf
    Topo2OSPFConfigConverter.new(opts)
  when :l3, :layer3
    Topo2Layer3ConfigConverter.new(opts)
  else
    # default (also :all)
    Topo2AllConfigConverter.new(opts)
  end
end
# exec:
# hagiwara@dev02:~/nwmodel/netomox-examples$ bundle exec ruby config_defs/topo2config.rb [--debug foo]

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
