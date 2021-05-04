# frozen_string_literal: true

require 'netomox'

# monkey patches
module Netomox
  module Topology
    # patch for Netomox::Topology::AttributeTable
    # It occurs warnings in ruby 2.7.x from 2.6.x.
    # This patch must be merged netomox (for ruby >=2.7.x)
    class AttributeTable
      def initialize(lines)
        @lines = lines.map { |line| AttributeTableLine.new(**line) }
      end
    end

    # patch for Netomox::Topology::Network
    class Network < TopoObjectBase
      def find_link_by_source(node_ref, tp_ref)
        source_data = {
          'source-node' => node_ref,
          'source-tp' => tp_ref
        }
        source_ref = TpRef.new(source_data, @name)
        @links.find { |link| link.source == source_ref }
      end

      def find_node_by_name(node_name)
        @nodes.find { |node| node.name == node_name }
      end
    end

    # patch for object base
    class TopoObjectBase
      # rewrite object name
      def name=(value)
        @name = value
        path_elements = @path.split('__')
        path_elements[-1] = @name
        @path = path_elements.join('__')
      end
    end

    # patch for Netomox::Topology::Node
    class Node < TopoObjectBase
      def find_all_supports_by_network(nw_name)
        @supports.find_all do |support|
          support.ref_network == nw_name
        end
      end

      def find_tp_by_name(tp_name)
        @termination_points.find { |tp| tp.name == tp_name }
      end

      def find_all_tps_except_loopback
        @termination_points.filter { |tp| tp.name !~ /Lo/i }
      end

      # key: method to read attribute (symbol)
      def find_all_tps_with_attribute(key)
        @termination_points.filter { |tp| tp.attribute.attribute?(key) }
      end

      def each_tps_except_loopback(&block)
        find_all_tps_except_loopback.each(&block)
      end

      def each_tps(&block)
        @termination_points.each(&block)
      end
    end

    # patch for term-point
    class TermPoint < TopoObjectBase
      def each_supports(&block)
        @supports.each(&block)
      end
    end

    # patch for attribute base
    class AttributeBase
      def attribute?(key)
        self.class.method_defined?(key)
      end
    end

    # patch for supports
    class SupportingRefBase < AttributeBase
      def ref_node
        path = ref_path.split('__')
        path.length > 1 ? path[1] : nil
      end
    end

    # patch for Netomox::Topology::TpRef
    class TpRef < SupportingRefBase
      def to_s
        "tp_ref:#{ref_path}"
      end
    end

    # L3 prefix
    class L3Prefix < AttributeBase
      def to_s
        "L3Prefix: prefix:#{prefix}, metric:#{metric}, flag:#{flag}"
      end
    end
  end
end
