# frozen_string_literal: true

require_relative './netomox_patch'

# Base methods to mix-in
module FrrConfigurable
  # find l3-node-name supported by ospf-proc/bgp-proc node
  # @param [Netomox::Topology::Node] node Node in ospf-proc or bgp-proc network
  # @return [String] supported layer3 node name
  def find_support_layer3_node_name(node)
    # ospf-proc node has single support node
    l3_node_support = node.find_all_supports_by_network('layer3').shift
    l3_node_support.ref_node
  end

  # @param [Array<String>] cmds Array of command strings
  # @return [Array<Hashie::Mash>]
  def format_cmds(cmds)
    cmds.map { |cmd| Hashie::Mash.new(cmd: cmd) }
  end

  # command list to vtysh command string
  # @param [String|Array<String>] cmds Array of command strings
  # @return [String] vtysh command string
  def vtysh_cmd(cmds)
    vtysh_opts = ['vtysh'].concat(cmds.map { |cmd| "-c \"#{cmd}\"" })
    if cmds.length > 1
      vtysh_opts.join("\n") # when multiple commands
    else
      vtysh_opts.join(' ') # when single command
    end
  end

  # command string formatter for node configuration
  # @param [Array<String>] cmds Array of command strings
  # @return [Hashie::Mash]
  def format_vtysh_cmds(cmds)
    Hashie::Mash.new(cmd: vtysh_cmd(cmds))
  end

  # command string formatter for node/test commands
  # @param [String] name Node name
  # @return [hashie::Mash] Config commands of specified node
  def find_node_config_by_name(name)
    @config[:node_configs].find { |config| config[:name] == name }
  end
end
