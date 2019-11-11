# frozen_string_literal: true

require 'csv'
require 'netomox'
require_relative 'csv/node_props_table'
require_relative 'csv/edges_layer1_table'

# rubocop:disable Metrics/AbcSize, Metrics/MethodLength
def register_bfl2_layer1(nws, target)
  node_props = NodePropsTable.new(target)
  l1_edges = EdgesLayer1Table.new(target)

  nws.register do
    network 'layer1' do
      node_props.each do |node_prop|
        node node_prop.node do
          node_prop.physical_interfaces.each do |interface|
            term_point interface
          end
        end
      end

      l1_edges.each do |edge|
        src_tp = node(edge.src.node).tp(edge.src.interface)
        dst_tp = node(edge.dst.node).tp(edge.dst.interface)
        src_tp.link_to(dst_tp)
      end
    end
  end
end
# rubocop:enable Metrics/AbcSize, Metrics/MethodLength
