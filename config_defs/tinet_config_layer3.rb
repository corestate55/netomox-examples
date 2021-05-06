# frozen_string_literal: true

require_relative './tinet_config_base'
require_relative './netomox_patch'

# Mix-in module to construct layer3 tinet config
module TinetConfigLayer3Module
  include TinetConfigBaseModule

  # @param [Netomox::Topology::Network] l3_nw layer3 network
  # @param [Netomox::Topology::Node] node Node in layer3 network
  def add_l3_node(l3_nw, node)
    @config[:nodes].push(config_l3_node(l3_nw, node))
  end

  # @param [Netomox::Topology::Node] node Node in layer3 network
  def add_l3_node_config(node)
    @config[:node_configs].push(config_l3_node_config(node))
  end

  # @param [Netomox::Topology::Network] l3_nw layer3 network
  # @param [Netomox::Topology::Node] node Node in layer3 network
  def add_l3_test(l3_nw, node)
    @config[:test][:cmds].concat(config_l3_test(l3_nw, node))
  end

  private

  def facing_tp(network, node, term_point)
    facing_interface_config = config_facing_interface(network, node, term_point)
    dst_node_name, dst_tp_name = facing_interface_config.split('#')
    dst_node = network.find_node_by_name(dst_node_name)
    dst_node.find_tp_by_name(dst_tp_name)
  end

  def config_facing_interface(network, node, term_point)
    found_link = network.find_link_by_source(node.name, term_point.name)
    # return "hostname#interface" format string
    found_link ? "#{found_link.destination.node_ref}##{found_link.destination.tp_ref}" : '_NONE_'
  end

  def config_l3_test(l3_nw, node)
    cmds = []
    node.find_all_tps_except_loopback.map do |tp|
      dst_tp = facing_tp(l3_nw, node, tp)
      next unless dst_tp.attribute.attribute?(:ip_addrs)

      dst_tp.attribute.ip_addrs.each do |dst_ip_addr|
        # test p2p link ping
        cmds.push("docker exec #{node.name} ping -c2 #{dst_ip_addr.split('/').shift}")
      end
    end
    format_cmds(cmds)
  end

  def config_l3_interfaces(l3_nw, node)
    node.find_all_tps_except_loopback.map do |tp|
      Hashie::Mash.new(
        name: tp.name,
        type: 'direct',
        args: config_facing_interface(l3_nw, node, tp)
      )
    end
  end

  def config_l3_node(l3_nw, node)
    Hashie::Mash.new(
      name: node.name,
      image: 'slankdev/frr',
      interfaces: config_l3_interfaces(l3_nw, node)
    )
  end

  def config_l3_node_cmds(node)
    cmds = ['/usr/lib/frr/frr start']
    ip_cmds = node.find_all_tps_with_attribute(:ip_addrs).map do |tp|
      tp.attribute.ip_addrs.map do |ip_addr|
        # notice: loopback interface name
        "ip addr add #{ip_addr} dev #{tp.name == 'Lo0' ? 'lo' : tp.name}"
      end
    end
    ip_cmds.nil? ? [] : ip_cmds.flatten!
    format_cmds(cmds.concat(ip_cmds))
  end

  def config_l3_node_config(node)
    Hashie::Mash.new(
      name: node.name,
      cmds: config_l3_node_cmds(node)
    )
  end
end

# Tinet config generator for layer3 topology model
class TinetConfigLayer3 < TinetConfigBase
  include TinetConfigLayer3Module
end
