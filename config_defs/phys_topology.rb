#!/usr/bin/env ruby
# frozen_string_literal: true

require 'json'
require 'yaml'
require_relative 'tinet_config'

# data converter (layer3 to tinet)
class Topo2PhysConfigConverter
  def initialize(file)
    @file = file
    @topology_data = read_topology_data
    @networks = convert_data_to_topology
    convert_interface_name
    @l3nw = @networks.find_network('layer3')
    @tinet_config = TinetConfig.new
    construct_config
  end

  def to_s
    "nws: #{@networks.networks.map(&:name)}"
  end

  def to_config
    @tinet_config.to_yaml
  end

  private

  # check and convert interface name to implement veth interface name constraints.
  def check_interface_name(name)
    warn "Interface name is invalid or too log: #{name}" if !name.ascii_only? || name.include?(' ') || name.length > 15
    name.tr!(' ', '_')
    name.tr!('/', '-')
    name
  end

  def construct_config
    @l3nw.nodes.each do |node|
      @tinet_config.add_node(@l3nw, node)
      @tinet_config.add_node_config(node)
      @tinet_config.add_test(@l3nw, node)
    end
  end

  def convert_ifname_for_nodes
    @networks.all_nodes do |node, _nw|
      node.each_tps do |tp|
        tp.name = check_interface_name(tp.name)
        tp.each_supports do |stp|
          stp.tp_ref = check_interface_name(stp.tp_ref)
        end
      end
    end
  end

  def convert_ifname_for_links
    @networks.all_links do |link, _nw|
      link.source.tp_ref = check_interface_name(link.source.tp_ref)
      link.destination.tp_ref = check_interface_name(link.destination.tp_ref)
    end
  end

  def convert_interface_name
    convert_ifname_for_nodes
    convert_ifname_for_links
  end

  def convert_data_to_topology
    Netomox::Topology::Networks.new(@topology_data)
  end

  def read_topology_data(opt_hash = {})
    JSON.parse(File.read(@file), opt_hash)
  end
end

# exec:
# hagiwara@dev02:~/nwmodel/netomox-examples$ bundle exec ruby config_defs/phys_topology.rb
file_dir = Pathname.new('~/nwmodel/netomox-examples/netoviz/static/model')
file_name = Pathname.new('bf_l3s1.json')
file_path = file_dir.join(file_name).expand_path
phys_config_converter = Topo2PhysConfigConverter.new(file_path)
puts phys_config_converter.to_config
