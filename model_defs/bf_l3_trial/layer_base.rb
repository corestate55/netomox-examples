# frozen_string_literal: true

require 'json'
require 'netomox'

# base class of layer topology converter
class TopologyLayerBase
  def initialize(debug: false, csv_dir: 'model_defs/bf_l3_trial/csv')
    @csv_dir = csv_dir # default: bundle exec ruby model_defs/bf_trial.rb
    @use_debug = debug
    @routes_table = read_table('routes.csv')
  end

  def puts_json
    nws = Netomox::DSL::Networks.new
    make_topology(nws)
    puts JSON.pretty_generate(nws.topo_data)
  end

  protected

  # debug print
  def debug(*message)
    puts message if @use_debug
  end

  def read_table(file_path)
    CSV.table("#{@csv_dir}/#{file_path}")
  end

  def prefix_attr(prefix, metric, protocol)
    { prefix: prefix, metric: metric, flag: [protocol] }
  end

  def routes_of(node, protocol = /.+/)
    @routes_table
      .find_all { |row| row[:node] == node && row[:protocol] =~ protocol }
      .map { |row| prefix_attr(row[:network], row[:metric], row[:protocol]) }
  end
end
