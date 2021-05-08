# frozen_string_literal: true

require 'netomox'

# monkey patches
module Netomox
  module Topology
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
      def find_all_tps_except_loopback
        @termination_points.filter { |tp| tp.name !~ /Lo/i }
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
