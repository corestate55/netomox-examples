# frozen_string_literal: true

require_relative './tinet_config_layer3'

# Mix-in module to construct bgp tinet config
module TinetConfigBGPModule
  include TinetConfigBaseModule

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

  def config_bgp_proc_node_config(asn, proc_node)
    format_vtysh_cmds([
                        'conf t',
                        "router bgp #{asn}",
                        "bgp router-id #{router_id(proc_node)}",
                        'bgp log-neighbor-changes',
                        'address-family ipv4 unicast',
                        # TODO: bgp configuration
                        'redistribute connected',
                        'exit-address-family',
                        'exit', # router bgp
                        'exit' # conf t
                      ])
  end
end

# Tinet config generator for bgp-proc topology model
class TinetConfigBGP < TinetConfigLayer3
  include TinetConfigBGPModule
end
