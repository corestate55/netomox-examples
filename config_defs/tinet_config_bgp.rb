# frozen_string_literal: true

require_relative './tinet_config_layer3'
require_relative './tinet_config_bgp_util'

# rubocop:disable Metrics/ModuleLength
# Mix-in module to construct bgp tinet config
module TinetConfigBGPModule
  include TinetConfigBaseModule

  # constants for bgp topology
  INTERNAL_AS_RANGE = (65_530..65_532).freeze
  EXTERNAL_AS_NETWORK = {
    65_533 => ['10.1.0.0/16'],
    65_534 => ['10.2.0.0/16']
  }.freeze

  # @param [Netomox::Topology::Network] bgp_as_nw
  # @param [Netomox::Topology::Network] bgp_proc_nw
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

  # @param [Netomox::Topology::Node] as_node node in bgp-as network
  # @returns [Integer]
  def asn_of_as_node(as_node)
    as_node.name.split(/as/).pop.to_i
  end

  # @return [Netomox::Topology::Node, nil]
  def find_parent(proc_node_ref, as_nw)
    parent = as_nw.nodes.find do |node|
      node.supports.find { |sup| sup.network_ref == 'bgp-proc' && sup.node_ref == proc_node_ref }
    end
    parent ? asn_of_as_node(parent) : nil
  end

  def find_bgp_proc_neighbors(proc_node, proc_nw, as_nw)
    neighbor_links = proc_nw.find_all_links_by_source_node(proc_node.name)
    neighbor_links.map do |link|
      peer_node_ref = link.destination.node_ref
      peer_node = proc_nw.find_node_by_name(peer_node_ref)
      peer_tp = peer_node.find_tp_by_name(link.destination.tp_ref)
      {
        orig_node: proc_node, # origin [Netomox::Topology::Node]
        peer_node: peer_node, # peer [Netomox::Topology::Node]
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
      cmd_list.push_bgp_common(cmds)
    end
    cmd_list.uniq_all!
    cmd_list
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
    cmd_list.push_bgp_common(common_cmds)
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

    cmd_list.push_bgp_common(["bgp cluster-id #{rr_config[:cluster_id]}"])
    cmd_list.push_bgp_ipv4uc(rr_config[:clients].map { |client| "neighbor #{client} route-reflector-client" })
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

  # static bgp-network definition for experiments
  def network_commands_static(asn)
    cmd_list = SectionCommandList.new # empty command list
    return cmd_list if INTERNAL_AS_RANGE.cover?(asn)

    cmd_list.push_bgp_ipv4uc(EXTERNAL_AS_NETWORK[asn].map { |pf| "network #{pf}" })
    cmd_list
  end

  def network_commands(proc_node)
    cmd_list = SectionCommandList.new # empty command list
    prefixes = find_network_config_in(proc_node)
    return cmd_list if prefixes.empty?

    cmd_list.push_bgp_ipv4uc(prefixes.map { |pref| "network #{pref}" })
    cmd_list
  end

  # @param [Integer] asn AS number of proc_node
  # @param [Netomox::Topology::Node] proc_node Node in bgp-proc network
  # @param [Netomox::Topology::Network] bgp_proc_nw bgp-proc network
  # @param [Netomox::Topology::Network] bgp_as_nw bgp-as network
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

  # @param [Integer] asn AS Number of proc_node
  # @param [Netomox::Topology::Node] proc_node BGP-process node
  # @param [Array<Hash>] proc_neighbors
  def config_bgp_proc_node_config(asn, proc_node, proc_neighbors)
    cmd_list = SectionCommandList.new
    cmd_list.push_conf_t([
                           "router bgp #{asn}",
                           "bgp router-id #{router_id(proc_node)}"
                         ])
    cmd_list.push_bgp_common(['bgp log-neighbor-changes'])
    cmd_list.append_section(confederation_commands(proc_node))
    cmd_list.append_section(route_reflector_commands(proc_node))
    cmd_list.append_section(neighbor_commands(asn, proc_node, proc_neighbors))
    cmd_list.append_section(network_commands(proc_node))
    cmd_list.append_section(network_commands_static(asn))
    format_vtysh_cmds(cmd_list.list_all_commands)
  end
end
# rubocop:enable Metrics/ModuleLength

# Tinet config generator for bgp-proc topology model
class TinetConfigBGP < TinetConfigLayer3
  include TinetConfigBGPModule
end
