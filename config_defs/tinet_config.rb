# frozen_string_literal: true

require 'hashie'
require_relative './netomox_patch'

# rubocop:disable Metrics/ClassLength
# Tinet config generator
class TinetConfig
  attr_reader :config

  def initialize
    @config = Hashie::Mash.new(nodes: [], node_configs: [], test: { cmds: [] })
  end

  def to_yaml
    check_ifname_in_configs
    YAML.dump(@config.to_hash)
  end

  # l3nw : Netomox::Topology::Network
  # node : Netomox::Topology::Node
  def add_node(l3nw, node)
    @config[:nodes].push(config_node(l3nw, node))
  end

  # node : Netomox::Topology::Node
  def add_node_config(node)
    @config[:node_configs].push(config_node_config(node))
  end

  def add_test(l3nw, node)
    @config[:test][:cmds].concat(config_test(l3nw, node))
  end

  private

  def facing_tp(l3nw, node, term_point)
    facing_interface_config = config_facing_interface(l3nw, node, term_point)
    dst_node_name, dst_tp_name = facing_interface_config.split('#')
    dst_node = l3nw.find_node_by_name(dst_node_name)
    dst_node.find_tp_by_name(dst_tp_name)
  end

  def config_test(l3nw, node)
    cmds = []
    node.find_all_non_loopback_tps.map do |tp|
      dst_tp = facing_tp(l3nw, node, tp)
      next unless dst_tp.attribute.attribute?(:ip_addrs)

      dst_tp.attribute.ip_addrs.each do |dst_ip_addr|
        # test p2p link ping
        cmds.push("docker exec #{node.name} ping -c2 #{dst_ip_addr.split('/').shift}")
      end
    end
    format_cmds(cmds)
  end

  def config_facing_interface(l3nw, node, term_point)
    found_link = l3nw.find_link_by_source(node.name, term_point.name)
    # return "hostname#interface" format string
    found_link ? "#{found_link.destination.node_ref}##{found_link.destination.tp_ref}" : '_NONE_'
  end

  def config_interfaces(l3nw, node)
    node.find_all_non_loopback_tps.map do |tp|
      Hashie::Mash.new(
        name: tp.name,
        type: 'direct',
        args: config_facing_interface(l3nw, node, tp)
      )
    end
  end

  def config_node(l3nw, node)
    Hashie::Mash.new(
      name: node.name,
      image: 'slankdev/frr',
      interfaces: config_interfaces(l3nw, node)
    )
  end

  def format_cmds(cmds)
    cmds.map { |cmd| Hashie::Mash.new(cmd: cmd) }
  end

  def config_node_cmds(node)
    cmds = ['/usr/lib/frr/frr start']
    ip_cmds = node.find_all_tps_with_attribute(:ip_addrs).map do |tp|
      tp.attribute.ip_addrs.map do |ip_addr|
        "ip addr add #{ip_addr} dev #{tp.name}"
      end
    end
    ip_cmds.nil? ? [] : ip_cmds.flatten!
    format_cmds(cmds.concat(ip_cmds))
  end

  def config_node_config(node)
    Hashie::Mash.new(
      name: node.name,
      cmds: config_node_cmds(node)
    )
  end

  def check_interface_name_body(name)
    warn "Interface name is invalid or too log: #{name}" if !name.ascii_only? || name.include?(' ') || name.length > 15
    name.tr!(' ', '_')
    name.tr!('/', '-')
    name
  end

  def check_interface_name(name)
    # hostname#interface format
    match = name.match(/(?<host>[\w.]+)#(?<interface>.*)/)
    if match
      host = match[:host]
      interface = check_interface_name_body(match[:interface])
      return [host, interface].join('#')
    end
    # interface name (itself)
    check_interface_name_body(name)
  end

  def check_cmd_interface_name(cmd)
    terms = cmd.split(/\s+/)
    # cmd: ip ... dev interface
    if terms[0] == 'ip' && terms.include?('dev')
      dev_index = terms.index('dev')
      terms[dev_index + 1] = check_interface_name_body(terms[dev_index + 1])
      return terms.join(' ')
    end
    cmd
  end

  def check_ifname_in_nodes
    @config[:nodes].each do |node|
      node[:interfaces].each do |interface|
        interface[:name] = check_interface_name(interface[:name])
        interface[:args] = check_interface_name(interface[:args])
      end
    end
  end

  def check_ifname_in_node_configs
    @config[:node_configs].each do |nconf|
      nconf[:cmds].each do |cmd|
        cmd[:cmd] = check_cmd_interface_name(cmd[:cmd])
      end
    end
  end

  def check_ifname_in_configs
    # chekc interface name: veth constraint
    # max 15 chars (add \0 at last: 16byte)
    # cannot use '/' and space
    check_ifname_in_nodes
    check_ifname_in_node_configs
  end
end
# rubocop:enable Metrics/ClassLength
