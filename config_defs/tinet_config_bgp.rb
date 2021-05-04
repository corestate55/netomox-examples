# frozen_string_literal: true

require_relative './tinet_config_layer3'

# Mix-in module to construct bgp tinet config
module TinetConfigBGPModule
  include TinetConfigBaseModule
  COMMON_INSERT_POINT_KEY = '!! bgp-common'
  IPV4UC_INSERT_POINT_KEY = '!! bgp-ipv4-unicast'

  def add_bgp_node_config_by_nw(bgp_as_nw, bgp_proc_nw)
    bgp_as_nw.nodes.each do |bgp_as_node|
      asn = bgp_as_node.name.split(/as/).pop.to_i
      bgp_as_node.supports.each do |support_node|
        next if support_node.network_ref != 'bgp-proc'

        bgp_proc_node = bgp_proc_nw.find_node_by_name(support_node.node_ref)
        add_bgp_proc_node_config(asn, bgp_proc_node)
      end
    end
  end

  private

  class SectionCommandList
    def initialize
      # initial: empty command list
      @section = {
        common: [],
        ipv4uc: []
      }
    end

    # commands: Array
    def push(section, commands)
      @section[section].push(*commands)
    end

    def push_common(commands)
      push(:common, commands)
    end

    def push_ipv4uc(commands)
      push(:ipv4uc, commands)
    end

    def common
      @section[:common]
    end

    def ipv4uc
      @section[:ipv4uc]
    end
  end

  def find_confederation_config_in(proc_node)
    confederation_flag_regexp = /confederation=(.*)/
    confederation_flag = proc_node.attribute.flags.find { |f| f =~ confederation_flag_regexp }
    return {} unless confederation_flag

    eval(confederation_flag_regexp.match(confederation_flag).captures.pop)
  end

  def confederation_commands(proc_node)
    confederation_config = find_confederation_config_in(proc_node)
    cmd_list = SectionCommandList.new # empty command list
    return cmd_list if confederation_config.empty?

    common_cmds = [
      "bgp confederation identifier #{confederation_config[:global_as]}"
    # "bgp confederation peers #{}" # TODO: local-as-peer
    ]
    cmd_list.push_common(common_cmds)
    cmd_list
  end

  def find_route_reflector_config_in(proc_node)
    rr_flag_regexp = /RR=(.*)/
    rr_flag = proc_node.attribute.flags.find { |f| f =~ rr_flag_regexp }
    return {} unless rr_flag

    eval(rr_flag_regexp.match(rr_flag).captures.pop)
  end

  def route_reflector_commands(proc_node)
    rr_config = find_route_reflector_config_in(proc_node)
    cmd_list = SectionCommandList.new # empty command list
    return cmd_list if rr_config.empty? || rr_config[:type] != :server

    cmd_list.push_common([ "bgp cluster-id #{rr_config[:cluster_id]}"])
    cmd_list.push_ipv4uc(rr_config[:clients].map { |client| "neighbor #{client} route-reflector-client" })
    cmd_list
  end

  def add_bgp_proc_node_config(asn, proc_node)
    l3_node_name = proc_node.attribute.name
    warn "AS:#{asn}, NODE:#{proc_node}, L3_NODE:#{l3_node_name}"
    target_node_config = find_node_config_by_name(l3_node_name)
    target_node_config[:cmds].push(config_bgp_proc_node_config(asn, proc_node))
  end

  def add_bgp_test(_node)
    # TODO: test commands for bgp network
  end

  def router_id(proc_node)
    # pick router_id: asXXXXX_N.N.N.N (external AS node), N.N.N.N (AS internal)
    proc_node.attribute.router_id.shift.split('_').pop
  end

  def insert_commands_before(cmds, insert_point_key, insert_cmds)
    insert_point = cmds.rindex(insert_point_key)
    cmds.insert(insert_point, *insert_cmds)
  end

  # cmd_list: SectionCommandList
  def insert_commands_to_section(cmds, cmd_list)
    insert_commands_before(cmds, COMMON_INSERT_POINT_KEY, cmd_list.common)
    insert_commands_before(cmds, IPV4UC_INSERT_POINT_KEY, cmd_list.ipv4uc)
  end

  def config_bgp_proc_node_config(asn, proc_node)
    cmds = [
      'conf t',
      "router bgp #{asn}",
      "bgp router-id #{router_id(proc_node)}",
      'bgp log-neighbor-changes',
      COMMON_INSERT_POINT_KEY,
      'address-family ipv4 unicast',
      IPV4UC_INSERT_POINT_KEY,
      'redistribute connected',
      'exit-address-family',
      'exit', # router bgp
      'exit' # conf t
    ]
    insert_commands_to_section(cmds, confederation_commands(proc_node))
    insert_commands_to_section(cmds, route_reflector_commands(proc_node))
    format_vtysh_cmds(cmds)
  end
end

# Tinet config generator for bgp-proc topology model
class TinetConfigBGP < TinetConfigLayer3
  include TinetConfigBGPModule
end
