# frozen_string_literal: true

require 'csv'
require 'set'
require 'netomox'
require 'ipaddr'
require_relative 'csv/edges_layer3_table.rb'
require_relative 'csv/edges_layer1_table.rb'
require_relative 'csv/sw_vlan_props_table'
require_relative 'csv/node_props_table'
require_relative 'csv/ip_owners_table'
require_relative 'csv/l3_segments_table'

# rubocop:disable Metrics/MethodLength
def make_link_group(l3_edges)
  link_group = {}
  l3_edges.each do |edge|
    src = edge.src.to_s
    dst = edge.dst.to_s
    if link_group[src]
      link_group[src].push(dst)
    else
      link_group[src] = [dst]
    end
  end
  link_group.keys.map { |k| Set.new([k, link_group[k]].flatten) }.uniq
end
# rubocop:enable Metrics/MethodLength

# rubocop:disable Metrics/AbcSize, Metrics/MethodLength
def make_segment_table(segments_l3, edges_l1, sw_vlan_props)
  seg_table = L3SegmentsTable.new
  segments_l3.each_with_index do |segment_l3, i|
    seg_name = "Seg.#{i}"
    seg_table.add_segment(seg_name)

    nodes = segment_l3.map { |s| EdgeLayer3.new_from_str(s) }
    nodes.each do |node|
      # L3-L2(vlan) mapping
      # if node/interface found in sw_vlan_props, use vlan_id directly.
      node_prop = sw_vlan_props.find_node_int(node.node, node.interface)
      if node_prop
        seg_table[seg_name].add_node(node_prop.vlan_id, node)
        next
      end

      # if not found, map with facing- (L1-connected-) interface vlan info
      dst_l1 = edges_l1.find_pair(node.node, node.interface)
      next unless dst_l1

      dst_prop = sw_vlan_props.find_node_int(dst_l1.node, dst_l1.interface)
      next unless dst_prop

      seg_table[seg_name].add_node(dst_prop.vlan_id, node) # src (host)
      seg_table[seg_name].add_node(dst_prop.vlan_id, dst_l1) # dst
      next
    end
  end
  seg_table
end
# rubocop:enable Metrics/AbcSize, Metrics/MethodLength

# rubocop:disable Metrics/AbcSize, Metrics/MethodLength
# rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
def register_bfl2_layer3(nws, target)
  # read data from csv
  l3_edges = EdgesLayer3Table.new(target)
  l1_edges = EdgesLayer1Table.new(target)
  sw_vlan_props = SwitchVlanPropsTable.new(target)
  node_props = NodePropsTable.new(target)
  ip_owners = IPOwnersTable.new(target)

  l3_segments = make_link_group(l3_edges)
  segment_table = make_segment_table(l3_segments, l1_edges, sw_vlan_props)
  # segment_table.dump # debug

  nws.register do
    network 'layer3' do
      type Netomox::NWTYPE_L3

      # make L3 segment node (P2MP:point-to-multipoint access area)
      segment_table.each_pair do |seg_name, seg|
        node seg_name do
          # set seg-node supports
          seg.nodes.each do |node| # L3Node obj
            node_prop = node_props.find_node(node.node)
            # l3-seg to l2-seg (with switch-vlan)
            next unless node_prop.switch?

            support_path = %W[layer2 #{l2node_name(node.node, node.vlan_id)}]
            # ignore duplicate support
            next if @supports.find { |sn| sn.path == support_path.join('__') }

            support support_path
          end

          # set segment network addr
          nw_addrs = []
          seg.nodes.each do |node| # L3Node obj
            ip_owner = ip_owners.find_node_int(node.node, node.interface)
            next unless ip_owner

            nw_addrs.push(IPAddr.new("#{ip_owner.ip}/#{ip_owner.mask}"))
          end
          prefixes = nw_addrs.map(&:to_s).sort.uniq.map do |addr|
            { prefix: addr }
          end
          attribute(prefixes: prefixes)

          # set seg-node term-points
          seg.nodes.each do |node| # L3Node obj
            # if node is switch
            if node_props.find_node(node.node).switch?
              ip_owner = ip_owners.find_node_int(node.node, node.interface)
              next unless ip_owner

              term_point ip_owner.node_name_by_device_type(false) do
                support_node = l2node_name(node.node, node.vlan_id)
                support %W[layer2 #{support_node} #{node.interface}]
              end
              next
            end

            # else-if node is host: use facing-(connected-) tp
            facing_tp = l1_edges.find_pair(node.node, node.interface)
            next unless facing_tp

            node_prop = node_props.find_node(facing_tp.node)
            next unless node_prop

            term_point node.node do
              support_node = if node_prop.host?
                               facing_tp.node
                             else
                               l2node_name(facing_tp.node, node.vlan_id)
                             end
              support %W[layer2 #{support_node} #{facing_tp.interface}]
            end
          end
        end
      end

      # make L3 node (node that has ip addr)
      ip_owners.each do |ip_owner|
        nw_addr = IPAddr.new("#{ip_owner.ip}/#{ip_owner.mask}")
        seg_prefix = { prefix: "#{nw_addr}/#{nw_addr.prefix}" }

        node_prop = node_props.find_node(ip_owner.node)
        node_name = ip_owner.node_name_by_device_type(node_prop.host?)

        # L3 host/routing-instance
        node node_name do
          attribute(prefixes: [seg_prefix])
          support %W[layer2 #{node_name}]
          term_point ip_owner.ip do
            support %W[layer2 #{node_name} #{ip_owner.interface}]
          end
        end

        # link to L3-segment-node
        # vlan_id = segment_table.find_vlan_id_owns(ip_owner.node, ip_owner.interface)
        seg_name = segment_table.seg_name_owns(ip_owner.node, ip_owner.interface)
        src = node(seg_name).tp(node_name)
        dst = node(node_name).tp(ip_owner.ip)
        src.bdlink_to(dst)
      end
    end
  end
end
# rubocop:enable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
# rubocop:enable Metrics/AbcSize, Metrics/MethodLength
