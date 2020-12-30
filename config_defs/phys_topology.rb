#!/usr/bin/env ruby
# frozen_string_literal: true

require 'json'
require 'yaml'
require 'hashie'
require 'netomox'

# monkey patches
module Netomox
  module Topology
    class Network < TopoObjectBase
      def find_link_source(node_ref, tp_ref)
        source_data = {
          'source-node' => node_ref,
          'source-tp' => tp_ref
        }
        source_ref = TpRef.new(source_data, @name)
        @links.find { |link| link.source == source_ref}
      end
    end

    class Node < TopoObjectBase
      def find_all_non_loopback_tps
        @termination_points.filter { |tp| tp.name !~ /Lo/i }
      end

      def find_all_tps_with_attribute(key)
        @termination_points.filter { |tp| tp.attribute.class.method_defined?(key) }
      end
    end
  end
end

# data converter (layer3 to tinet)
class Topo2PhysConfigConverter
  def initialize(file)
    @file = file
    @topology_data = read_topology_data
    @networks = json2topology
    @l3nw = @networks.find_network('layer3')
    @tinet_config = Hashie::Mash.new(nodes: [], node_configs: [])
    construct_config
  end

  def to_s
    "nws: #{@networks.networks.map { |nw| nw.name }}"
  end

  def to_config
    YAML.dump(@tinet_config.to_hash)
  end

  private

  def config_facing_interface(node, tp)
    source_data = {
      'source-node' => node.name,
      'source-tp' => tp.name
    }
    source_ref = Netomox::Topology::TpRef.new(source_data, @l3nw.name)
    link = @l3nw.links.find { |link| link.source == source_ref }
    link ? "#{link.destination.node_ref}##{link.destination.tp_ref}" : '_NONE_'
  end

  def config_interfaces(node)
    node.find_all_non_loopback_tps.map do |tp|
      Hashie::Mash.new(
        name: tp.name,
        type: 'direct',
        args: config_facing_interface(node, tp)
      )
    end
  end

  def config_node(node)
    Hashie::Mash.new(
      name: node.name,
      image: 'slankdev/frr',
      interfaces: config_interfaces(node)
    )
  end

  def config_node_cmds(node)
    cmds = [ '/usr/lib/frr/frr start' ]
    ip_cmds = node.find_all_tps_with_attribute(:ip_addrs).map do |tp|
      tp.attribute.ip_addrs.map do |ip_addr|
        "ip addr add #{ip_addr} dev #{tp.name}"
      end
    end
    ip_cmds.nil? ? [] : ip_cmds.flatten!
    cmds.concat(ip_cmds).map { |cmd| { cmd: cmd }}
  end

  def config_node_config(node)
    Hashie::Mash.new(
      name: node.name,
      cmds: config_node_cmds(node)
    )
  end

  def construct_config
    @l3nw.nodes.each do |node|
      @tinet_config[:nodes].push(config_node(node))
      @tinet_config[:node_configs].push(config_node_config(node))
    end
  end

  def json2topology
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
