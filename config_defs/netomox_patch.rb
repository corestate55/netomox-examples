# frozen_string_literal: true

require 'netomox'

# monkey patches
module Netomox
  module Topology
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
