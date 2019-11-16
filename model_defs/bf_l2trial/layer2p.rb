# frozen_string_literal: true

require 'json'
require_relative 'pseudo_model'
require_relative 'csv/node_props_table'
require_relative 'csv/edges_layer1_table'
require_relative 'csv/sw_vlan_props_table'
require_relative 'csv/ip_owners_table'
require_relative 'csv/interface_prop_table'

# rubocop:disable Metrics/ClassLength
# L2 data builder
class L2DataBuilder < DataBuilderBase
  def initialize(target)
    super()
    @node_props = NodePropsTable.new(target)
    @l1_edges = EdgesLayer1Table.new(target)
    @sw_vlan_props = SwitchVlanPropsTable.new(target)
    @ip_owners = IPOwnersTable.new(target)
    @if_props = InterfacePropertiesTable.new(target)
    @networks = make_networks
  end

  private

  def make_l2tp_attr(if_prop)
    base = { max_frame_size: if_prop.mtu }
    if if_prop.swp_trunk?
      base[:eth_encap] = if_prop.switchport_encap
      base[:vlan_id_names] = if_prop.swp_vlans.map do |id|
        { id: id, name: "VL#{id}" }
      end
    elsif if_prop.swp_access?
      base[:port_vlan_id] = if_prop.access_vlan
    end
    base
  end

  def get_l2tp_attr(node, interface)
    if_prop = @if_props.find_node_int(node, interface)
    return unless if_prop

    make_l2tp_attr(if_prop)
  end

  def make_switch_vlan_node_tps(interfaces)
    interfaces.map do |interface|
      ptp = PTermPoint.new(interface.interface)
      if interface.physical_interface?
        ptp.attribute = get_l2tp_attr(interface.node, interface.interface)
        ptp.supports.push(%W[layer1 #{interface.node} #{interface.interface}])
      end
      ptp
    end
  end

  def make_switch_vlan_nodes
    @sw_vlan_props.each do |sw_vlan_prop|
      pnode = PNode.new(sw_vlan_prop.l2node_name)
      pnode.supports.push(%W[layer1 #{sw_vlan_prop.node}])
      pnode.tps = make_switch_vlan_node_tps(sw_vlan_prop.interfaces)
      @nodes.push(pnode)
    end
  end

  def make_l3nodes_tps(ip_owner)
    ptp = PTermPoint.new(ip_owner.interface)
    if ip_owner.physical_interface?
      ptp.supports.push(%W[layer1 #{ip_owner.node} #{ip_owner.interface}])
    end
    [ptp]
  end

  def make_l3nodes
    @ip_owners.each do |ip_owner|
      node_prop = @node_props.find_node(ip_owner.node)
      node_name = ip_owner.node_name_by_device_type(node_prop.host?)
      pnode = PNode.new(node_name)
      pnode.supports.push(%W[layer1 #{ip_owner.node}])
      pnode.tps = make_l3nodes_tps(ip_owner)
      @nodes.push(pnode)
    end
  end

  def make_nodes
    make_switch_vlan_nodes
    make_l3nodes
    @nodes
  end

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

  def warning_vlan_mapping(src_node, src_interface, src_if_prop, dst_if_prop)
    src_str = "#{src_node}[#{src_interface}]"
    dst_str = "#{dst.node}[#{dst.interface}]"
    warn "WARNING: #{src_str} => #{dst_str} : vlan mismatch?"
    methods = %i[switchport switchport_mode swp_vlans]
    warn "  - src: #{src_if_prop.values(methods)}"
    warn "  - dst: #{dst_if_prop.values(methods)}"
  end

  # rubocop:disable Metrics/MethodLength
  def get_dst_vid(src_vlan_id, src_node, src_interface, dst, dst_node_prop)
    src_if_prop = @if_props.find_node_int(src_node, src_interface)
    dst_if_prop = @if_props.find_node_int(dst.node, dst.interface)

    if dst_node_prop.host? ||
       normal_vlan_connect(src_vlan_id, src_if_prop, dst_if_prop)
      src_vlan_id
    elsif access_vlan_connect(src_if_prop, dst_if_prop)
      dst_if_prop.access_vlan
    else
      # L3 connection? or ERROR
      warning_vlan_mapping(src_node, src_interface, src_if_prop, dst_if_prop)
      src_vlan_id # OK?
    end
  end
  # rubocop:enable Metrics/MethodLength

  def make_vrf2vlan_link
    @ip_owners.each do |ip_owner|
      node_prop = @node_props.find_node(ip_owner.node)
      node_name = ip_owner.node_name_by_device_type(node_prop.host?)
      next unless node_prop.switch?

      # L2-L3 mapping
      # fixed link for routing_instance (GRT/VRF)
      #   -> same interface: SVI
      add_link(node_name, ip_owner.interface,
               ip_owner.l2node_name, ip_owner.interface)
    end
  end

  def link_host2vlan(src, dst, src_vid, src_node, src_l2nn)
    # interface config check (L2-L3 mapping)
    dst_node_prop = @node_props.find_node(dst.node)
    dst_vid = get_dst_vid(src_vid, src_node, src.interface, dst, dst_node_prop)
    return unless dst_vid

    # linking
    # NOTICE: sw_vlan_prop/edges(L1) don't have GRT/VRF-vlan link info)
    if dst_node_prop.host?
      add_link(src_l2nn, src.interface, dst.node, dst.interface)
    else
      dst_l2node_name = l2node_name(dst.node, dst_vid)
      add_link(src_l2nn, src.interface,
               dst_l2node_name, dst.interface, false)
    end
  end

  def make_host2vlan_link
    @sw_vlan_props.each do |sw_vlan_prop|
      methods = %i[vlan_id node l2node_name]
      src_vid, src_node, src_l2nn = sw_vlan_prop.values(methods)

      sw_vlan_prop.interfaces.each do |src|
        dst = @l1_edges.find_pair(src_node, src.interface)
        next unless dst

        link_host2vlan(src, dst, src_vid, src_node, src_l2nn)
      end
    end
  end

  def make_links
    make_vrf2vlan_link
    make_host2vlan_link
    @links
  end

  def make_networks
    @network = PNetwork.new('layer2')
    @network.type = Netomox::NWTYPE_L2
    @network.nodes = make_nodes
    @network.links = make_links
    @networks.networks.push(@network)
    @networks
  end
end
# rubocop:enable Metrics/ClassLength
#
## TEST
# l2db = L2DataBuilder.new('sample3')
# l2db.dump
# puts JSON.pretty_generate(l2db.topo_data)
