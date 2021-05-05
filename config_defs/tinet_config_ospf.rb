# frozen_string_literal: true

require 'ipaddress'
require_relative './tinet_config_layer3'

# Mix-in module to construct ospf tinet config
module TinetConfigOSPFModule
  include TinetConfigBaseModule

  def add_ospf_node_config(node)
    target_node_config = node_config_by_ospf_node(node)
    target_node_config[:cmds].push(config_ospf_node_cmds(node))
  end

  def add_ospf_test(node)
    @config[:test][:cmds].concat(config_ospf_test(node))
  end

  private

  def ospf_status_check_cmds
    [
      'show ip ospf neighbor',
      'show ip route ospf'
    ]
  end

  def config_ospf_test(node)
    l3_node_name = find_support_layer3_node_name(node)
    cmds = ospf_status_check_cmds.map do |cmd|
      "docker exec #{l3_node_name} vtysh -c \"#{cmd}\""
    end
    format_cmds(cmds)
  end

  def find_support_layer3_node_name(node)
    # ospf-proc node has single support node
    l3_node_support = node.find_all_supports_by_network('layer3').shift
    l3_node_support.ref_node
  end

  def find_node_config_by_ospf_node(node)
    l3_node_name = find_support_layer3_node_name(node)
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
    cmds.push('exit') # router ospf
    cmds.push('exit') # conf t
    format_vtysh_cmds(cmds)
  end
end

# Tinet config generator for ospf-proc topology model
class TinetConfigOSPF < TinetConfigLayer3
  include TinetConfigOSPFModule
end
