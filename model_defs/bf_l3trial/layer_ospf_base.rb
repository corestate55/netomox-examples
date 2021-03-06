# frozen_string_literal: true

require_relative 'layer_base'
require_relative 'csv/as_area_table'

# layer topology converter for batfish ospf network data
class OSPFTopologyConverterBase < TopologyLayerBase
  def initialize(opts = {})
    super(**opts)

    setup_as_area_table
  end

  private

  def setup_as_area_table
    table_of = {
      as_numbers: @as_numbers,
      edges_bgp: @edges_bgp_table,
      config_ospf_area: @config_ospf_area_table
    }
    @as_area_table = ASAreaTable.new(@use_debug, table_of)
    debug '# as_area_table: ', @as_area_table
  end
end
