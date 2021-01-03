# frozen_string_literal: true

require 'hashie'
require 'ipaddress'
require_relative './netomox_patch'

# rubocop:disable Metrics/ClassLength
# Tinet config generator
class TinetConfig
  attr_reader :config

  def initialize
    @config = Hashie::Mash.new(nodes: [], node_configs: [], test: { cmds: [] })
  end

  def to_yaml
    # change multiple line string format of commands:
    # blick/chomp(|-) to fold/chomp(>-)
    YAML.dump(@config.to_hash).tr('cmd: |-', 'cmd: >-')
  end

  # l3_nw : Netomox::Topology::Network
  # node : Netomox::Topology::Node
  def add_l3_node(l3_nw, node)
    @config[:nodes].push(config_l3_node(l3_nw, node))
  end

  # node : Netomox::Topology::Node
  def add_l3_node_config(node)
    @config[:node_configs].push(config_l3_node_config(node))
  end

  def add_l3_test(l3_nw, node)
    @config[:test][:cmds].concat(config_l3_test(l3_nw, node))
  end

  def add_ospf_node_config(node)
    target_node_config = node_config_by_ospf_node(node)
    target_node_config[:cmds].push(config_ospf_node_cmds(node))
  end

  private

  def format_cmds(cmds)
    cmds.map { |cmd| Hashie::Mash.new(cmd: cmd) }
  end

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
        "ip addr add #{ip_addr} dev #{tp.name}"
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

  def find_node_config_by_name(name)
    @config[:node_configs].find do |config|
      config[:name] == name
    end
  end

  def find_node_config_by_ospf_node(node)
    # ospf-proc node has single support node
    l3_node_support = node.find_all_supports_by_network('layer3').shift
    l3_node_name = l3_node_support.ref_node
    find_node_config_by_name(l3_node_name)
  end

  def node_config_by_ospf_node(node)
    node_config = find_node_config_by_ospf_node(node)
    if node_config
      node_config
    else
      new_node_config = Hashie::Mash.new(name: node.name, cmds: [])
      @config[:node_configs].push(new_node_config)
      new_node_config
    end
  end

  def format_vtysh_cmds(cmds)
    vtysh_cmds = ['vtysh']
    vtysh_cmds.concat(cmds.map { |cmd| "-c \"#{cmd}\"" })
    Hashie::Mash.new(cmd: vtysh_cmds.join("\n"))
  end

  def static_ospf_cmds
    [
      'log-adjacency-changes',
      'passive-interface lo', # TODO: loopback interface name?
      'redistribute connected'
    ]
  end

  def ospf_network_cmd(ip_ospf_str)
    area, ip_str = ip_ospf_str.split(':')
    area.tr!('area', '')
    ip = IPAddress::IPv4.new(ip_str)
    "network #{ip.network.to_string} area #{area}"
  end

  def config_ospf_node_cmds(node)
    cmds = ['conf t']
    # the proc number is not used in the ospfd of FRR.
    # proc_id = node.attribute.name.tr('process_', '')
    # cmds.push("router ospf #{proc_id}")
    cmds.push('router ospf')
    # add static ospf config
    cmds.concat(static_ospf_cmds)

    # add ospf network commands
    node.each_tps_except_loopback do |tp|
      tp.attribute.ip_addrs.each do |ip_ospf_str|
        cmds.push(ospf_network_cmd(ip_ospf_str))
      end
    end
    format_vtysh_cmds(cmds)
  end
end
# rubocop:enable Metrics/ClassLength
