# frozen_string_literal: true

require 'ipaddress'
require_relative './tinet_config_base'

# Mix-in module to construct ospf tinet config
module TinetConfigOSPFModule
  include TinetConfigBaseModule

  # constants
  OSPF_STATUS_CHECK_CMDS = [
    'show ip ospf neighbor',
    'show ip route ospf'
  ].freeze
  STATIC_OSPF_CMDS = [
    'log-adjacency-changes',
    'passive-interface lo',
    'redistribute connected'
  ].freeze

  # @param [Netomox::Topology::Network] ospf_proc_nw ospf-proc network
  def add_ospf_node_config(ospf_proc_nw)
    ospf_proc_nw.nodes.each do |node|
      target_node_config = node_config_by_ospf_node(node)
      target_node_config[:cmds].push(config_ospf_node_cmds(node))
    end
  end

  # @param [Netomox::Topology::Network] ospf_proc_nw ospf-proc network
  def add_ospf_test(ospf_proc_nw)
    ospf_proc_nw.nodes.each do |node|
      @config[:test][:cmds].concat(config_ospf_test(node))
    end
  end

  private

  def config_ospf_test(node)
    l3_node_name = find_support_layer3_node_name(node)
    cmds = OSPF_STATUS_CHECK_CMDS.map do |cmd|
      "docker exec #{l3_node_name} #{vtysh_cmd([cmd])}"
    end
    format_cmds(cmds)
  end

  def find_node_config_by_ospf_node(node)
    l3_node_name = find_support_layer3_node_name(node)
    find_node_config_by_name(l3_node_name)
  end

  # @param [Netomox::Topology::Node] node Node in ospf-proc network
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

  def ospf_network_cmd(ip_ospf_str)
    area, ip_str = ip_ospf_str.split(':')
    area.tr!('area', '')
    ip = IPAddress::IPv4.new(ip_str)
    "network #{ip.network.to_string} area #{area}"
  end

  # @param [Netomox::Topology::Node] node Node in ospf-proc network
  def config_ospf_node_cmds(node)
    cmds = ['conf t']
    # the proc number is not used in the ospfd of FRR.
    # proc_id = node.attribute.name.tr('process_', '')
    # cmds.push("router ospf #{proc_id}")
    cmds.push('router ospf')
    # add static ospf config
    cmds.concat(STATIC_OSPF_CMDS)

    # add ospf network commands
    node.each_tps_except_loopback do |tp|
      tp.attribute.ip_addrs.each do |ip_ospf_str|
        cmds.push(ospf_network_cmd(ip_ospf_str))
      end
    end
    cmds.push('exit') # router ospf
    cmds.push('exit') # conf t
    format_vtysh_cmds(cmds)
  end
end
