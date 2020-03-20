# frozen_string_literal: true

require 'csv'
require_relative 'layer_base'

# layer topology converter for batfish bgp network data
class BGPTopologyConverterBase < TopologyLayerBase
  def initialize(opts = {})
    super(opts)
  end
end
