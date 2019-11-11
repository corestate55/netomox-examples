# frozen_string_literal: true

require 'csv'
require 'netomox'
require_relative 'csv/node_props_table'
require_relative 'csv/edges_layer1_table'
require_relative 'csv/sw_vlan_props_table'
require_relative 'csv/ip_owners_table'
require_relative 'csv/interface_prop_table'

def normal_vlan_connect(vlan_id, src_prop, dst_prop)
  src_prop.swp_trunk? && dst_prop.swp_trunk? &&
    dst_prop.swp_has_vlan?(vlan_id) ||
    src_prop.swp_access? && dst_prop.swp_access? &&
      src_prop.access_vlan == dst_prop.access_vlan
end

def access_vlan_connect(src_prop, dst_prop)
  src_prop.swp_access? && dst_prop.swp_access? &&
    src_prop.access_vlan != dst_prop.access_vlan
end

# rubocop:disable Metrics/AbcSize
def get_dst_vlan_id(if_props,
                    src_vlan_id, src_node, src_interface, dst, dst_node_prop)
  src_if_prop = if_props.find_node_int(src_node, src_interface)
  dst_if_prop = if_props.find_node_int(dst.node, dst.interface)

  if dst_node_prop.host? || normal_vlan_connect(src_vlan_id, src_if_prop, dst_if_prop)
    src_vlan_id
  elsif access_vlan_connect(src_if_prop, dst_if_prop)
    dst_if_prop.access_vlan
  else
    # L3 connection? or ERROR
    src_str = "#{src_node}[#{src_interface}]"
    dst_str = "#{dst.node}[#{dst.interface}]"
    warn "WARNING: #{src_str} => #{dst_str} : vlan mismatch?"
    warn "  - src: #{src_if_prop.switchport},#{src_if_prop.switchport_mode},#{src_if_prop.swp_vlans}"
    warn "  - dst: #{dst_if_prop.switchport},#{dst_if_prop.switchport_mode},#{dst_if_prop.swp_vlans}"
    src_vlan_id # OK?
  end
end
# rubocop:enable Metrics/AbcSize

def get_l2tp_attr(if_props, node, interface)
  if_prop = if_props.find_node_int(node, interface)
  return nil unless if_prop

  base = { max_frame_size: if_prop.mtu }

  if if_prop.swp_trunk?
    base[:eth_encap] = if_prop.switchport_encap
    base[:vlan_id_names] = if_prop.swp_vlans.map do |id|
      { id: id, name: "VL#{id}" }
    end
    base
  elsif if_prop.swp_access?
    base[:port_vlan_id] = if_prop.access_vlan
    base
  end
end

# rubocop:disable Metrics/AbcSize, Metrics/MethodLength
# rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
def register_bfl2_layer2(nws, target)
  # read data from csv
  node_props = NodePropsTable.new(target)
  l1_edges = EdgesLayer1Table.new(target)
  sw_vlan_props = SwitchVlanPropsTable.new(target)
  ip_owners = IPOwnersTable.new(target)
  if_props = InterfacePropertiesTable.new(target)

  nws.register do
    network 'layer2' do
      type Netomox::NWTYPE_L2
      attribute(name: 'layer2', flags: ['layer2'])

      # make nodes (switch vlan)
      sw_vlan_props.each do |sw_vlan_prop|
        node sw_vlan_prop.l2node_name do
          support %W[layer1 #{sw_vlan_prop.node}]
          sw_vlan_prop.interfaces.each do |interface|
            term_point interface.interface do
              if interface.physical_interface?
                attribute(
                  get_l2tp_attr(if_props, sw_vlan_prop.node, interface.interface)
                )
                support %W[layer1 #{interface.node} #{interface.interface}]
              end
            end
          end
        end
      end

      # make nodes (host/vrf)
      ip_owners.each do |ip_owner|
        node_prop = node_props.find_node(ip_owner.node)
        node_name = ip_owner.node_name_by_device_type(node_prop.host?)
        node node_name do
          support %W[layer1 #{ip_owner.node}]
          term_point ip_owner.interface do
            if ip_owner.physical_interface?
              support %W[layer1 #{ip_owner.node} #{ip_owner.interface}]
            end
          end
        end
        next if node_prop.host?

        # L2-L3 mapping
        # fixed link for routing_instance (GRT/VRF)
        #   -> same interface: SVI
        src_tp = node(node_name).tp(ip_owner.interface)
        dst_tp = node(ip_owner.l2node_name).tp(ip_owner.interface)
        src_tp.bdlink_to(dst_tp)
      end

      # make links
      sw_vlan_props.each do |sw_vlan_prop|
        src_vlan_id = sw_vlan_prop.vlan_id
        src_node = sw_vlan_prop.node
        src_l2node_name = sw_vlan_prop.l2node_name

        sw_vlan_prop.interfaces.each do |src|
          dst = l1_edges.find_pair(src_node, src.interface)
          next unless dst

          # interface config check (L2-L3 mapping)
          dst_node_prop = node_props.find_node(dst.node)
          dst_vlan_id = get_dst_vlan_id(
            if_props, src_vlan_id, src_node, src.interface, dst, dst_node_prop)
          next unless dst_vlan_id

          # linking
          # NOTICE: sw_vlan_prop/edges(L1) don't have GRT/VRF-vlan link info)
          if dst_node_prop.host?
            src = node(src_l2node_name).tp(src.interface)
            dst = node(dst.node).tp(dst.interface)
            src.bdlink_to(dst)
          else
            dst_l2node_name = l2node_name(dst.node, dst_vlan_id)
            src = node(src_l2node_name).tp(src.interface)
            dst = node(dst_l2node_name).tp(dst.interface)
            src.link_to(dst)
          end
        end
      end
    end
  end
end
# rubocop:enable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
# rubocop:enable Metrics/AbcSize, Metrics/MethodLength
