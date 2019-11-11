# frozen_string_literal: true

require 'forwardable'
require_relative './table_base'

# row of node-properties table
class NodePropsTableRecord
  attr_accessor :node, :device_type, :interfaces, :vrfs

  def initialize(record)
    @node = record[:node]
    @device_type = record[:device_type]
    @interfaces = interfaces2array(record[:interfaces])
    @vrfs = record[:vrfs]
  end

  def physical_interfaces
    # use physical interface (ignore SVI)
    @interfaces.filter { |d| d !~ /Vlan*/ }
  end

  def host?
    @device_type == 'HOST'
  end

  def switch?
    @device_type == 'SWITCH'
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

  def find_node(node)
    @records.find { |r| r.node == node }
  end
end
