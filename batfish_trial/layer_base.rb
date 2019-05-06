require 'json'
require 'netomox'

class TopologyLayerBase
  def initialize(debug: false)
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
    CSV.table(file_path)
  end
end
