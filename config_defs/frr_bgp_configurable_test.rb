# frozen_string_literal: true

# Mix-in module to construct bgp tinet config
module FrrBGPConfigurable
  # constants
  BGP_STATUS_CHECK_CMDS = [
    'show ip bgp summary',
    'show ip bgp detail',
    'show ip bgp nexthop',
    'show ip route bgp'
  ].freeze

  # @param [Netomox::Topology::Network] bgp_as_nw bgp-as network
  # @param [Netomox::Topology::Network] bgp_proc_nw bgp-proc network
  def add_bgp_test(bgp_as_nw, bgp_proc_nw)
    # init topology data base
    @bgp_as_nw = bgp_as_nw
    @bgp_proc_nw = bgp_proc_nw
    # make test configs
    add_show_bgp_route_test
    add_inter_as_ping_test
  end

  private

  def add_show_bgp_route_test
    l3_node_names = @bgp_proc_nw.nodes.map { |node| find_support_layer3_node_name(node) }
    cmds = l3_node_names.product(BGP_STATUS_CHECK_CMDS).map do |node_cmd_pair|
      "docker exec #{node_cmd_pair[0]} #{vtysh_cmd([node_cmd_pair[1]])}"
    end
    @config[:test][:cmds].concat(format_cmds(cmds))
  end

  def add_inter_as_ping_test
    @bgp_as_nw.nodes.each do |orig_node|
      src_node_names = l3_node_names_in_as(orig_node)
      dst_ipaddrs = external_as_border_ips(orig_node)
      @config[:test][:cmds].concat(config_bgp_test(src_node_names, dst_ipaddrs))
    end
  end

  # @param [Array<String>] src_node_names Node name in layer3 network
  # @param [Array<String>] dst_ipaddrs IP Addresses to ping from src_node
  # @return [Array<Hashie::Mash>] Commands
  def config_bgp_test(src_node_names, dst_ipaddrs)
    cmds = src_node_names.product(dst_ipaddrs).map do |node_ip_pair|
      "docker exec #{node_ip_pair[0]} ping -c2 #{node_ip_pair[1]}"
    end
    format_cmds(cmds)
  end

  # @param [String] proc_node_name Node name in bgp-proc network
  def find_supported_l3node(proc_node_name)
    proc_node = @bgp_proc_nw.find_node_by_name(proc_node_name)
    find_support_layer3_node_name(proc_node)
  end

  # @param [Netomox::Topology::Node] orig_node Node in bgp-as network
  # @return [Array<String>] Node names in l3-network
  def l3_node_names_in_as(orig_node)
    orig_node.find_all_supports_by_network('bgp-proc')
             .map(&:node_ref)
             .map { |proc_node_name| find_supported_l3node(proc_node_name) }
  end

  # @param [Netomox::Topology::Node] orig_node Node in bgp-as network
  # @return [Array<String>] IP address list
  def external_as_border_ips(orig_node)
    nodes_exclude_self = @bgp_as_nw.nodes.reject { |node| node.name == orig_node.name }
    tps_in_external_as = nodes_exclude_self.map(&:termination_points)
    tps_in_external_as.flatten.map(&:name).sort
  end
end
