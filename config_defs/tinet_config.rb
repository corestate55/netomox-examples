# frozen_string_literal: true

require 'hashie'
require_relative './netomox_patch'

class TinetConfig
  attr_reader :config

  def initialize
    @config = Hashie::Mash.new(nodes: [], node_configs: [])
  end

  def to_yaml
    check_config_interface
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

  private

  def config_facing_interface(l3nw, node, tp)
    source_data = {
      'source-node' => node.name,
      'source-tp' => tp.name
    }
    source_ref = Netomox::Topology::TpRef.new(source_data, l3nw.name)
    link = l3nw.links.find { |link| link.source == source_ref }
    link ? "#{link.destination.node_ref}##{link.destination.tp_ref}" : '_NONE_'
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

  def check_interface_name_body(name)
    if !name.ascii_only? || name.include?(' ') || name.length > 15
      warn "Interface name is invalid or too log: #{name}"
    end
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

  def check_config_interface
    # chekc interface name: veth constraint
    # max 15 chars (add \0 at last: 16byte)
    # cannot use '/' and space
    @config[:nodes].each do |node|
      node[:interfaces].each do |interface|
        interface[:name] = check_interface_name(interface[:name])
        interface[:args] = check_interface_name(interface[:args])
      end
    end
    @config[:node_configs].each do |nconf|
      nconf[:cmds].each do |cmd|
        cmd[:cmd] = check_cmd_interface_name(cmd[:cmd])
      end
    end
  end
end
