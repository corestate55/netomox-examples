# frozen_string_literal: true

require 'netomox'

# monkey patches
module Netomox
  module Topology
    class Network < TopoObjectBase
      def find_link_source(node_ref, tp_ref)
        source_data = {
          'source-node' => node_ref,
          'source-tp' => tp_ref
        }
        source_ref = TpRef.new(source_data, @name)
        @links.find { |link| link.source == source_ref}
      end
    end

    class Node < TopoObjectBase
      def find_all_non_loopback_tps
        @termination_points.filter { |tp| tp.name !~ /Lo/i }
      end

      def find_all_tps_with_attribute(key)
        @termination_points.filter { |tp| tp.attribute.class.method_defined?(key) }
      end
    end
  end
end
