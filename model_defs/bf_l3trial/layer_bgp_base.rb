# frozen_string_literal: true

require 'csv'
require_relative 'layer_base'

# layer topology converter for batfish bgp network data
class BGPTopologyConverterBase < TopologyLayerBase
  def initialize(opts = {})
    super(opts)

    table_of = {
      routes: @routes_table,
      ip_owners: @ip_owners_table,
      edges_bgp: @edges_bgp_table
    }
    @config_bgp_proc_table = ConfigBGPProcTable.new(@target, table_of)
  end
end
