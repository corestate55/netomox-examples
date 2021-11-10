# frozen_string_literal: true

require 'json'
require_relative '../bf_common/pseudo_model'
require_relative 'csv/sw_vlan_props_table'
require_relative 'csv/interface_prop_table'

# L2 data builder
class L2DataBuilder < DataBuilderBase
  def initialize(target, layer1p)
    super()
    @layer1p = layer1p
    @sw_vlan_props = SwitchVlanPropsTable.new(target)
    @intf_props = InterfacePropertiesTable.new(target)
  end

  def make_networks
    @network = PNetwork.new('layer2')
    setup_nodes_and_links
    @networks.push(@network)
    @networks
  end

  private

  def access_port_vlan_id(tp_prop)
    return tp_prop.access_vlan if tp_prop.swp_access?

    0 # Host port (not specified vlan)
  end

  def same_access_vlan?(src_tp_prop, dst_tp_prop)
    [access_port_vlan_id(src_tp_prop), access_port_vlan_id(dst_tp_prop)].filter { |n| n != 0 }.length < 2
  end

  def port_l2_config_check(src_tp_prop, dst_tp_prop)
    # TODO: it must check "vlan bridge" existence on device
    if src_tp_prop.almost_access? && dst_tp_prop.almost_access? && same_access_vlan?(src_tp_prop, dst_tp_prop)
      return {
        type: :access,
        src_vlan_id: access_port_vlan_id(src_tp_prop),
        dst_vlan_id: access_port_vlan_id(dst_tp_prop)
      }
    end
    if src_tp_prop.swp_trunk? && dst_tp_prop.swp_trunk?
      return {
        type: :trunk,
        vlan_ids: src_tp_prop.allowed_vlans & dst_tp_prop.allowed_vlans
      }
    end
    { type: :error }
  end

  def add_l2_node_tp(l1_node, l1_tp, vlan_id)
    l2_node_name = vlan_id > 0 ? l1_node.name + "_Vlan#{vlan_id}" : l1_node.name
    new_node = @network.node(l2_node_name)
    new_tp = new_node.term_point(l1_tp.name)
    [new_node.name, new_tp.name]
  end

  def add_l2_node_tp_link(src_node, src_tp, src_vlan_id, dst_node, dst_tp, dst_vlan_id)
    src_l2_node, src_l2_tp = add_l2_node_tp(src_node, src_tp, src_vlan_id)
    dst_l2_node, dst_l2_tp = add_l2_node_tp(dst_node, dst_tp, dst_vlan_id)
    @network.link(src_l2_node, src_l2_tp, dst_l2_node, dst_l2_tp)
  end

  def add_l2_nodes_and_links(src_node, src_tp, dst_node, dst_tp)
    src_tp_prop = @intf_props.find_record_by_node_intf(src_node.name, src_tp.name)
    dst_tp_prop = @intf_props.find_record_by_node_intf(dst_node.name, dst_tp.name)
    warn "- src {#{src_node.name}__#{src_tp.name}:#{src_tp_prop}}, dst {#{dst_node.name}__#{dst_tp.name}:#{dst_tp_prop}}"
    check_result = port_l2_config_check(src_tp_prop, dst_tp_prop)
    if check_result[:type] == :access
      add_l2_node_tp_link(src_node, src_tp, check_result[:src_vlan_id], dst_node, dst_tp, check_result[:dst_vlan_id])
    elsif check_result[:type] == :trunk
      check_result[:vlan_ids].each do |vlan_id|
        add_l2_node_tp_link(src_node, src_tp, vlan_id, dst_node, dst_tp, vlan_id)
      end
    else
      warn "# ERROR: L2 Config Check Error"
    end
  end

  def setup_nodes_and_links
    @layer1p.links.each do |link|
      src_node = @layer1p.find_node_by_name(link.src.node)
      src_tp = src_node.find_tp_by_name(link.src.tp)
      dst_node = @layer1p.find_node_by_name(link.dst.node)
      dst_tp = dst_node.find_tp_by_name(link.dst.tp)
      add_l2_nodes_and_links(src_node, src_tp, dst_node, dst_tp)
    end
  end
end
