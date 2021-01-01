# frozen_string_literal: true

require 'forwardable'
require_relative 'table_base'

# row of config_ospf_proc table
class ConfigOSPFProcTableRecord < TableRecordBase
  attr_accessor :node, :vrf, :process_id, :areas, :router_id, :area_border

  def initialize(record, table_of, debug = false)
    super(debug)

    @node = record[:node]
    @vrf = record[:vrf]
    @process_id = record[:process_id]
    @areas = record[:areas]
    @router_id = record[:router_id]
    @area_border = record[:area_border]
  end

  def to_s
    [
      'ConfigOSPFProcTableRec:',
      "#{@node},#{@vrf},#{@process_id},#{@areas},#{@router_id},#{@area_border}"
    ].join(' ')
  end
end

# config_ospf_proc table
class ConfigOSPFProcTable < TableBase
  extend Forwardable

  def_delegators :@records, :each, :find, :[]

  def initialize(target, table_of, debug = false)
    super(target, 'config_ospf_proc.csv', debug)

    @records = @orig_table.map do |record|
      ConfigOSPFProcTableRecord.new(record, table_of, debug)
    end
  end

  def find_by_node_and_proc(node, proc_id)
    @records.find { |r| r.node == node && r.process_id == proc_id }
  end

  def to_s
    @records.map(&:to_s).join("\n").to_s
  end
end
