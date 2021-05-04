# frozen_string_literal: true

require_relative './tinet_config_layer3'

# rubocop:disable Metrics/ModuleLength
# Mix-in module to construct bgp tinet config
module TinetConfigBGPModule
  include TinetConfigBaseModule

  # constants
  COMMON_INSERT_POINT_KEY = '!! bgp-common'
  IPV4UC_INSERT_POINT_KEY = '!! bgp-ipv4-unicast'
  # constants for bgp topology
  INTERNAL_AS_RANGE = (65_530..65_532).freeze
  EXTERNAL_AS_NETWORK = {
    65_533 => ['10.1.0.0/16'],
    65_534 => ['10.2.0.0/16']
  }.freeze

  def add_bgp_node_config_by_nw(bgp_as_nw, bgp_proc_nw)
    bgp_as_nw.nodes.each do |bgp_as_node|
      asn = asn_of_as_node(bgp_as_node)
      bgp_as_node.supports.each do |support_node|
        next if support_node.network_ref != 'bgp-proc'

        bgp_proc_node = bgp_proc_nw.find_node_by_name(support_node.node_ref)
        add_bgp_proc_node_config(asn, bgp_proc_node, bgp_proc_nw, bgp_as_nw)
      end
    end
  end

  private

  def asn_of_as_node(as_node)
    as_node.name.split(/as/).pop.to_i
  end

  def find_links_origin(proc_node, proc_nw)
    proc_nw.links.find_all { |link| link.source.node_ref == proc_node.name }
  end

  def find_parent(proc_node_ref, as_nw)
    parent = as_nw.nodes.find do |node|
      node.supports.find { |sup| sup.network_ref == 'bgp-proc' && sup.node_ref == proc_node_ref }
    end
    parent ? asn_of_as_node(parent) : nil
  end

  def find_bgp_proc_neighbors(proc_node, proc_nw, as_nw)
    neighbor_links = find_links_origin(proc_node, proc_nw)
    neighbor_links.map do |link|
      peer_node_ref = link.destination.node_ref
      peer_node = proc_nw.find_node_by_name(peer_node_ref)
      peer_tp = peer_node.find_tp_by_name(link.destination.tp_ref)
      {
        orig_node: proc_node, # origin
        peer_node: peer_node, # peer
        peer_ip: peer_tp.attribute.ip_addrs, # tp name contains ':N' duplicated count
        asn: find_parent(peer_node_ref, as_nw),
        confederation: find_confederation_config_in(peer_node)
      }
    end
  end

  def neighbor_ibgp_cmds(peer_ip, remote_asn)
    neighbor_str = "neighbor #{peer_ip}"
    [
      "#{neighbor_str} remote-as #{remote_asn}",
      "#{neighbor_str} update-source lo"
    ]
  end

  def neighbor_confed_ebgp_cmds(peer_ip, remote_asn, local_asn)
    [
      *neighbor_ebgp_cmds(peer_ip, remote_asn),
      "bgp confederation peers #{local_asn}"
    ]
  end

  def neighbor_ebgp_cmds(peer_ip, remote_asn)
    ["neighbor #{peer_ip} remote-as #{remote_asn}"]
  end

  def confed_ebgp(orig_asn, orig_confed, neighbor)
    neighbor[:asn] != orig_asn && # asn is same as confederation.local_as
      !neighbor[:confederation].empty? && !orig_confed.empty? &&
      neighbor[:confederation][:global_as] == orig_confed[:global_as]
  end

  # rubocop:disable Metrics/AbcSize
  def select_neighbor_commands(asn, confederation, neighbor)
    if neighbor[:asn] == asn
      neighbor_ibgp_cmds(neighbor[:peer_node].attribute.router_id[0], neighbor[:asn])
    elsif confed_ebgp(asn, confederation, neighbor)
      neighbor_confed_ebgp_cmds(neighbor[:peer_ip][0], neighbor[:asn], neighbor[:confederation][:local_as])
    else
      remote_asn = neighbor[:confederation].empty? ? neighbor[:asn] : neighbor[:confederation][:global_as]
      neighbor_ebgp_cmds(neighbor[:peer_ip][0], remote_asn)
    end
  end
  # rubocop:enable Metrics/AbcSize

  def neighbor_commands(asn, proc_node, proc_neighbors)
    cmd_list = SectionCommandList.new
    confederation = find_confederation_config_in(proc_node) # origin config
    proc_neighbors.each do |neighbor|
      cmds = select_neighbor_commands(asn, confederation, neighbor)
      cmd_list.push_common(cmds)
    end
    cmd_list.uniq_all!
    cmd_list
  end

  # sectioned command list
  class SectionCommandList
    def initialize
      # initial: empty command list
      @section = { common: [], ipv4uc: [] }
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

    def uniq_all!
      @section.each_key { |key| @section[key].uniq! }
    end
  end

  def find_confederation_config_in(proc_node)
    confederation_flag_regexp = /confederation=(.*)/
    confederation_flag = proc_node.attribute.flags.find { |f| f =~ confederation_flag_regexp }
    return {} unless confederation_flag

    # rubocop:disable Security/Eval
    eval(confederation_flag_regexp.match(confederation_flag).captures.pop)
    # rubocop:enable Security/Eval
  end

  def confederation_commands(proc_node)
    confederation_config = find_confederation_config_in(proc_node)
    cmd_list = SectionCommandList.new # empty command list
    return cmd_list if confederation_config.empty?

    common_cmds = [
      "bgp confederation identifier #{confederation_config[:global_as]}"
      # "bgp confederation peers #{}" # added in neighbor commands
    ]
    cmd_list.push_common(common_cmds)
    cmd_list
  end

  def find_route_reflector_config_in(proc_node)
    rr_flag_regexp = /RR=(.*)/
    rr_flag = proc_node.attribute.flags.find { |f| f =~ rr_flag_regexp }
    return {} unless rr_flag

    # rubocop:disable Security/Eval
    eval(rr_flag_regexp.match(rr_flag).captures.pop)
    # rubocop:enable Security/Eval
  end

  def route_reflector_commands(proc_node)
    rr_config = find_route_reflector_config_in(proc_node)
    cmd_list = SectionCommandList.new # empty command list
    return cmd_list if rr_config.empty? || rr_config[:type] != :server

    cmd_list.push_common(["bgp cluster-id #{rr_config[:cluster_id]}"])
    cmd_list.push_ipv4uc(rr_config[:clients].map { |client| "neighbor #{client} route-reflector-client" })
    cmd_list
  end

  def find_network_config_in(proc_node)
    network_regexp = /network=(.*)/
    network_flag = proc_node.attribute.flags.find { |f| f =~ network_regexp }
    return [] unless network_flag

    # rubocop:disable Security/Eval
    eval(network_regexp.match(network_flag).captures.pop)
    # rubocop:enable Security/Eval
  end

  def network_commands_static(asn)
    cmd_list = SectionCommandList.new # empty command list
    return cmd_list if INTERNAL_AS_RANGE.cover?(asn.to_i)

    cmd_list.push_ipv4uc(EXTERNAL_AS_NETWORK[asn.to_i].map { |pf| "network #{pf}" })
    cmd_list
  end

  def network_commands(proc_node)
    cmd_list = SectionCommandList.new # empty command list
    prefixes = find_network_config_in(proc_node)
    return cmd_list if prefixes.empty?

    cmd_list.push_ipv4uc(prefixes.map { |pref| "network #{pref}" })
    cmd_list
  end

  def add_bgp_proc_node_config(asn, proc_node, bgp_proc_nw, bgp_as_nw)
    l3_node_name = proc_node.attribute.name
    warn "AS:#{asn}, NODE:#{proc_node}, L3_NODE:#{l3_node_name}"
    target_node_config = find_node_config_by_name(l3_node_name)
    proc_neighbors = find_bgp_proc_neighbors(proc_node, bgp_proc_nw, bgp_as_nw)
    target_node_config[:cmds].push(config_bgp_proc_node_config(asn, proc_node, proc_neighbors))
  end

  def add_bgp_test(_node)
    # TODO: test commands for bgp network
  end

  def router_id(proc_node)
    # pick router_id: asXXXXX_N.N.N.N (external AS node), N.N.N.N (AS internal)
    proc_node.attribute.router_id[0].split('_').pop
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

  def clean_insert_point(cmds)
    cmds.delete(COMMON_INSERT_POINT_KEY)
    cmds.delete(IPV4UC_INSERT_POINT_KEY)
  end

  # rubocop:disable Metrics/MethodLength
  def config_bgp_proc_node_config(asn, proc_node, proc_neighbors)
    cmds = [
      'conf t',
      "router bgp #{asn}",
      "bgp router-id #{router_id(proc_node)}",
      'bgp log-neighbor-changes',
      COMMON_INSERT_POINT_KEY,
      'address-family ipv4 unicast',
      IPV4UC_INSERT_POINT_KEY,
      # 'redistribute connected',
      'exit-address-family',
      'exit', # router bgp
      'exit' # conf t
    ]
    insert_commands_to_section(cmds, confederation_commands(proc_node))
    insert_commands_to_section(cmds, route_reflector_commands(proc_node))
    insert_commands_to_section(cmds, neighbor_commands(asn, proc_node, proc_neighbors))
    insert_commands_to_section(cmds, network_commands(proc_node))
    insert_commands_to_section(cmds, network_commands_static(asn))
    clean_insert_point(cmds)
    format_vtysh_cmds(cmds)
  end
  # rubocop:enable Metrics/MethodLength
end
# rubocop:enable Metrics/ModuleLength

# Tinet config generator for bgp-proc topology model
class TinetConfigBGP < TinetConfigLayer3
  include TinetConfigBGPModule
end
