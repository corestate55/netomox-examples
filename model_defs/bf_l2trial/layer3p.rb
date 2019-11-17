# frozen_string_literal: true

require 'json'
require 'set'
require 'ipaddr'
require_relative 'pseudo_model'
require_relative 'csv/edges_layer3_table.rb'
require_relative 'csv/edges_layer1_table.rb'
require_relative 'csv/sw_vlan_props_table'
require_relative 'csv/node_props_table'
require_relative 'csv/ip_owners_table'
require_relative 'csv/l3_segments_table'

# rubocop:disable Metrics/ClassLength
# L3 data builder
class L3DataBuilder < DataBuilderBase
  def initialize(target)
    super()
    @l3_edges = EdgesLayer3Table.new(target)
    @l1_edges = EdgesLayer1Table.new(target)
    @sw_vlan_props = SwitchVlanPropsTable.new(target)
    @node_props = NodePropsTable.new(target)
    @ip_owners = IPOwnersTable.new(target)
    @segment_table = make_segment_table
    make_networks
  end

  private

  def make_link_group
    link_group = {}
    @l3_edges.each do |edge|
      src, dst = edge.values(%i[src dst]).map(&:to_s)
      link_group[src] = [] unless link_group[src]
      link_group[src].push(dst)
    end
    link_group.keys.map { |k| Set.new([k, link_group[k]].flatten) }.uniq
  end

  def add_seg_nodes_by_l1(seg, node)
    dst_l1 = @l1_edges.find_pair(node.node, node.interface)
    return unless dst_l1

    dst_prop = @sw_vlan_props.find_node_int(dst_l1.node, dst_l1.interface)
    return unless dst_prop

    seg.add_node(dst_prop.vlan_id, node) # src (host)
    seg.add_node(dst_prop.vlan_id, dst_l1) # dst
  end

  def add_segment_nodes(seg, node)
    # L3-L2(vlan) mapping
    # if node/interface found in sw_vlan_props, use vlan_id directly.
    node_prop = @sw_vlan_props.find_node_int(node.node, node.interface)
    if node_prop
      seg.add_node(node_prop.vlan_id, node)
    else
      add_seg_nodes_by_l1(seg, node)
    end
  end

  def make_segment_table
    seg_table = L3SegmentsTable.new

    l3_segments = make_link_group
    l3_segments.each_with_index do |segment_l3, i|
      seg_name = "Seg.#{i}"
      seg_table.add_segment(seg_name)

      nodes = segment_l3.map { |s| EdgeLayer3.new_from_str(s) }
      nodes.each { |node| add_segment_nodes(seg_table[seg_name], node) }
    end
    seg_table
  end

  def make_l3seg_node_supports(seg)
    supports = []
    seg.nodes.each do |node| # L3Node obj
      node_prop = @node_props.find_node(node.node)
      # l3-seg to l2-seg (with switch-vlan)
      next unless node_prop.switch?

      support_path = %W[layer2 #{l2node_name(node.node, node.vlan_id)}]
      supports.push(support_path)
    end
    supports.uniq # avoid duplicated support
  end

  def make_l3seg_node_attr(seg)
    nw_addrs = []
    seg.nodes.each do |node| # L3Node obj
      ip_owner = @ip_owners.find_node_int(node.node, node.interface)
      next unless ip_owner

      nw_addrs.push(IPAddr.new("#{ip_owner.ip}/#{ip_owner.mask}"))
    end
    prefixes = nw_addrs.map(&:to_s).uniq.map { |addr| { prefix: addr } }
    { prefixes: prefixes }
  end

  def make_l3seg_node_sw_tp(node)
    # node is switch
    ip_owner = @ip_owners.find_node_int(node.node, node.interface)
    return unless ip_owner

    ptp = PTermPoint.new(ip_owner.node_name_by_device_type(false))
    support_node = l2node_name(node.node, node.vlan_id)
    ptp.supports.push(%W[layer2 #{support_node} #{node.interface}])
    ptp
  end

  def make_host_tp_snode(node_prop, facing_tp, node)
    if node_prop.host?
      facing_tp.node
    else
      l2node_name(facing_tp.node, node.vlan_id)
    end
  end

  def make_l3seg_node_host_tp(node)
    # node is host: use facing-(connected-) tp
    facing_tp = @l1_edges.find_pair(node.node, node.interface)
    return unless facing_tp

    node_prop = @node_props.find_node(facing_tp.node)
    return unless node_prop

    ptp = PTermPoint.new(node.node)
    support_node = make_host_tp_snode(node_prop, facing_tp, node)
    ptp.supports.push(%W[layer2 #{support_node} #{facing_tp.interface}])
    ptp
  end

  def make_l3seg_node_tps(seg)
    tps = []
    seg.nodes.each do |node| # L3Node obj
      if @node_props.find_node(node.node).switch?
        tps.push(make_l3seg_node_sw_tp(node))
        next
      end
      tps.push(make_l3seg_node_host_tp(node))
    end
    tps.delete_if(&:nil?)
  end

  def make_l3seg_nodes
    @segment_table.each_pair do |seg_name, seg|
      pnode = PNode.new(seg_name)
      pnode.supports = make_l3seg_node_supports(seg)
      pnode.attribute = make_l3seg_node_attr(seg)
      pnode.tps = make_l3seg_node_tps(seg)
      @nodes.push(pnode)
    end
  end

  def make_l3node_tps(node_name, ip_owner)
    ptp = PNode.new(ip_owner.ip)
    ptp.attribute = { ip_addrs: [ip_owner.ip] }
    ptp.supports = [%W[layer2 #{node_name} #{ip_owner.interface}]]
    [ptp]
  end

  def make_l3node(node_name, seg_prefix, ip_owner)
    # L3 host/routing-instance
    pnode = PNode.new(node_name)
    pnode.attribute = { prefixes: [seg_prefix] }
    pnode.supports.push(%W[layer2 #{node_name}])
    pnode.tps = make_l3node_tps(node_name, ip_owner)
    pnode
  end

  def make_l3nodes
    # make L3 node (node that has ip addr)
    @ip_owners.each do |ip_owner|
      nw_addr = IPAddr.new("#{ip_owner.ip}/#{ip_owner.mask}")
      seg_prefix = { prefix: "#{nw_addr}/#{nw_addr.prefix}" }

      node_prop = @node_props.find_node(ip_owner.node)
      node_name = ip_owner.node_name_by_device_type(node_prop.host?)
      @nodes.push(make_l3node(node_name, seg_prefix, ip_owner))
    end
  end

  def make_nodes
    make_l3seg_nodes
    make_l3nodes
    @nodes
  end

  def make_node2seg_links
    @ip_owners.each do |ip_owner|
      node_prop = @node_props.find_node(ip_owner.node)
      node_name = ip_owner.node_name_by_device_type(node_prop.host?)
      # link to L3-segment-node
      seg_name = @segment_table.seg_name_owns(ip_owner.node, ip_owner.interface)
      add_link(seg_name, node_name, node_name, ip_owner.ip)
    end
  end

  def make_links
    make_node2seg_links
    @links
  end

  def make_networks
    @network = PNetwork.new('layer3')
    @network.type = Netomox::NWTYPE_L3
    @network.nodes = make_nodes
    @network.links = make_links
    @networks.networks.push(@network)
    @networks
  end
end
# rubocop:enable Metrics/ClassLength

## TEST
# l3db = L3DataBuilder.new('sample3')
# l3db.dump
# puts JSON.pretty_generate(l3db.topo_data)
