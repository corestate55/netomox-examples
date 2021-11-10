# frozen_string_literal: true

require 'forwardable'
require_relative 'table_base'

# row of node-properties table
class NodePropsTableRecord < TableRecordBase
  attr_accessor :node, :config_format, :interfaces, :vrfs

  def initialize(record)
    super()
    @node = record[:node]
    @config_format = record[:configuration_format]
    @interfaces = interfaces2array(record[:interfaces])
    @vrfs = record[:vrfs]
  end

  def physical_interfaces
    # use physical interface (ignore SVI)
    @interfaces.filter { |d| d !~ /Vlan*/ }
  end

  def host?
    @config_format == 'HOST'
  end

  def switch?
    %w[CISCO_IOS].include?(@config_format)
  end

  private

  # rubocop:disable Security/Eval
  def interfaces2array(interfaces)
    eval(interfaces).sort
  end
  # rubocop:enable Security/Eval
end

# node-properties table
class NodePropsTable < TableBase
  extend Forwardable

  def_delegators :@records, :each, :find, :[]

  def initialize(target)
    super(target, 'node_props.csv')
    @records = @orig_table.map { |r| NodePropsTableRecord.new(r) }
  end

  # alias
  def find_record_by_node(node_name)
    find_node(node_name)
  end

  def find_node(node)
    @records.find { |r| r.node == node }
  end
end
