# frozen_string_literal: true

require 'forwardable'
require_relative 'table_base'
require_relative 'ip_owners_table'

# row of config_ospf_area table
class ConfigOSPFAreaTableRecord < TableRecordBase
  attr_accessor :node, :area, :process_id,
                :active_interfaces, :passive_interfaces

  # rubocop:disable Security/Eval
  def initialize(record, ip_owners_table, debug = false)
    super(debug)

    @node = record[:node]
    @area = record[:area]
    @process_id = record[:process_id]
    @active_interfaces = eval(record[:active_interfaces])
    @passive_interfaces = eval(record[:passive_interfaces])
    @ip_owners_table = ip_owners_table
  end
  # rubocop:enable Security/Eval

  def as_area(asn)
    area, proc_id, interfaces = area_interfaces
    make_as_area_row(asn, area, node, proc_id, interfaces)
  end

  private

  def make_as_area_row(asn, area, node, proc_id, interfaces)
    {
      as: asn,
      area: area,
      node: node,
      process_id: proc_id,
      interfaces: interfaces
    }
  end

  def make_interface_info(interfaces)
    interfaces.map do |interface|
      ip_rec = @ip_owners_table.find_by_node_int(@node, interface)
      {
        interface: interface,
        ip: ip_rec.ip_mask_str
      }
    end
  end

  def area_interfaces
    interfaces = [@active_interfaces, @passive_interfaces].flatten
    if_info = make_interface_info(interfaces)
    [@area, @process_id, if_info]
  end
end

# config_ospf_area table
class ConfigOSPFAreaTable < TableBase
  extend Forwardable

  def_delegators :@records, :each, :find, :[]

  def initialize(target, debug = false)
    super(target, 'config_ospf_area.csv', debug)

    ip_owners_table = IPOwnersTable.new(target)
    @records = @orig_table.map do |record|
      ConfigOSPFAreaTableRecord.new(record, ip_owners_table, debug)
    end
  end

  def find_all_area_of(node)
    @records
      .find_all { |r| r.node == node }
      .map(&:area)
      .sort
  end

  def find_all_by_node(node)
    @records.find_all { |r| r.node == node }
  end

  def area_border_data(asn, node)
    # NOTICE: node name is UNIQUE in WHOLE AS.
    {
      asn: asn,
      node: node,
      areas: find_all_area_of(node)
    }
  end
end
