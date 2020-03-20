# frozen_string_literal: true

require 'forwardable'
require_relative 'table_base'

# Primitive class of config_bgp_proc table row.
class ConfigBGPProcTableRecordCore < TableRecordBase
  attr_accessor :node, :router_id, :neighbors

  # rubocop:disable Security/Eval
  def initialize(record, debug = false)
    super(debug)

    @node = record[:node]
    @router_id = record[:router_id]
    @neighbors = eval(record[:neighbors])
  end
  # rubocop:enable Security/Eval
end

# Primitive class of config_bgp_proc_table.
# used in edges_bgp to prevent cyclic loading of tables.
# they reads each other.
class ConfigBGPProcTableCore < TableBase
  def initialize(target, debug = false)
    super(target, 'config_bgp_proc.csv', debug)

    @records = @orig_table.map do |record|
      ConfigBGPProcTableRecordCore.new(record, debug)
    end
  end

  def find_by_node(node)
    @records.find { |r| r.node == node }
  end

  def find_router_id(node)
    # NOTICE: assume single process in node
    #   bgp_proc_table has only "neighbor ip list" (destination ip list)
    find_by_node(node).router_id
  end
end
