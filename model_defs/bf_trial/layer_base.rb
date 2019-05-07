require 'json'
require 'netomox'

class TopologyLayerBase
  def initialize(debug: false, csv_dir: 'model_defs/bf_trial/csv')
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

  def make_prefix_attr(prefix, metric, protocol)
    { prefix: prefix, metric: metric, flag: [protocol] }
  end

  def routes_of(node, protocol = /.+/)
    @routes_table
      .find_all { |row| row[:node] == node && row[:protocol] =~ protocol }
      .map { |row| make_prefix_attr(row[:network], row[:metric], row[:protocol]) }
  end
end
