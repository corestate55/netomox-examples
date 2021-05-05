# frozen_string_literal: true

require 'json'
require_relative '../bf_common/pseudo_model'
require_relative 'csv/routes_table'
require_relative 'csv/ip_owners_table'
require_relative 'csv/edges_bgp_table'
require_relative 'csv/config_bgp_peer_table'
require_relative 'csv/config_bgp_proc_table'
require_relative 'csv/config_ospf_area_table'
require_relative 'csv/config_ospf_proc_table'

# base class of layer topology converter
class TopologyLayerBase < DataBuilderBase
  def initialize(target: '', debug: false, csv_dir: '')
    super()
    @target = target
    @csv_dir = csv_dir
    @use_debug = debug

    # commons for bgp-*, ospf-* and layer3
    setup_routes_table
    setup_ip_owners_table

    # commons for bgp-* and ospf-*
    setup_edges_bgp_table
    setup_as_numbers_table
    setup_config_bgp_peer_table
    setup_config_ospf_proc_table
    setup_config_ospf_area_table
  end

  def to_json(*_args)
    JSON.pretty_generate(topo_data)
  end

  protected

  # debug print
  def debug(*message)
    puts message if @use_debug
  end

  private

  def setup_routes_table
    @routes_table = RoutesTable.new(@target)
  end

  def setup_ip_owners_table
    @ip_owners_table = IPOwnersTable.new(@target)
  end

  def setup_edges_bgp_table
    table_of = {
      ip_owners: @ip_owners_table,
      # Use config_bgp_proc_table_CORE to avoid cyclic loading.
      config_bgp_proc: ConfigBGPProcTableCore.new(@target)
    }
    @edges_bgp_table = EdgesBGPTable.new(@target, table_of, @use_debug)
  end

  def setup_config_bgp_peer_table
    @config_bgp_peer_table = ConfigBGPPeerTable.new(@target, @use_debug)
    debug '# config_bgp_peer: ', @config_bgp_peer_table
  end

  def setup_as_numbers_table
    @as_numbers = @edges_bgp_table.as_numbers
    debug '# as_numbers: ', @as_numbers
  end

  def setup_config_ospf_proc_table
    table_of = {}
    @config_ospf_proc_table = ConfigOSPFProcTable.new(@target, table_of)
    debug '# config_ospf_proc: ', @config_ospf_proc_table
  end

  def setup_config_ospf_area_table
    table_of = {
      routes: @routes_table,
      ip_owners: @ip_owners_table,
      config_ospf_proc: @config_ospf_proc_table
    }
    @config_ospf_area_table = ConfigOSPFAreaTable.new(@target, table_of)
    debug '# config_ospf_area: ', @config_ospf_area_table
  end
end
