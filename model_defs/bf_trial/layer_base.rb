require 'json'
require 'netomox'

class TopologyLayerBase
  def initialize(debug: false, csv_dir: 'model_defs/bf_trial/csv')
    @csv_dir = csv_dir # default: bundle exec ruby model_defs/bf_trial.rb
    @use_debug = debug
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
end
