# frozen_string_literal: true

require 'json'
require 'netomox'
require_relative 'csv/routes_table'
require_relative 'csv/ip_owners_table'
require_relative 'csv/edges_bgp_table'
require_relative 'csv/config_bgp_proc_table'

# base class of layer topology converter
class TopologyLayerBase
  # rubocop:disable Metrics/MethodLength
  def initialize(target: '', debug: false, csv_dir: '')
    @target = target
    @csv_dir = csv_dir # default: bundle exec ruby model_defs/bf_trial.rb
    @use_debug = debug

    # commons for bgp-*, ospf-* and layer3
    @routes_table = RoutesTable.new(@target)
    @ip_owners_table = IPOwnersTable.new(@target)

    # commons for bgp-* and ospf-*
    table_of = {
      ip_owners: @ip_owners_table,
      # avoid cyclic loading
      config_bgp_proc: ConfigBGPProcTableCore.new(@target)
    }
    @edges_bgp_table = EdgesBGPTable.new(@target, table_of, @use_debug)
    @as_numbers = @edges_bgp_table.as_numbers
    debug '# as_numbers: ', @as_numbers
  end
  # rubocop:enable Metrics/MethodLength

  def to_json(*_args)
    nws = Netomox::DSL::Networks.new
    make_topology(nws)
    JSON.pretty_generate(nws.topo_data)
  end

  def make_topology(_nws)
    raise 'Abstract method must be override.'
  end

  protected

  # debug print
  def debug(*message)
    puts message if @use_debug
  end
end
