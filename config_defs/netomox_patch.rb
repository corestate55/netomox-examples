# frozen_string_literal: true

require 'netomox'

# monkey patches
module Netomox
  module Topology
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

    # patch for Netomox::Topology::Node
    class Node < TopoObjectBase
      def find_tp_by_name(tp_name)
        @termination_points.find { |tp| tp.name == tp_name }
      end

      def find_all_non_loopback_tps
        @termination_points.filter { |tp| tp.name !~ /Lo/i }
      end

      def find_all_tps_with_attribute(key)
        @termination_points.filter { |tp| tp.attribute.attribute?(key) }
      end
    end

    # patch for attribute base
    class AttributeBase
      def attribute?(key)
        self.class.method_defined?(key)
      end
    end

    # patch for Netomox::Topology::TpRef
    class TpRef < SupportingRefBase
      def to_s
        "tp_ref:#{ref_path}"
      end
    end
  end
end
