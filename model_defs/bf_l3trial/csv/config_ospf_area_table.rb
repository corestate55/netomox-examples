# frozen_string_literal: true

require 'forwardable'
require_relative 'table_base'
require_relative 'as_area_util'

# row of config_ospf_area table
class ConfigOSPFAreaTableRecord < TableRecordBase
  attr_accessor :node, :area, :process_id,
                :active_interfaces, :passive_interfaces

  # rubocop:disable Security/Eval
  def initialize(record, table_of, debug = false)
    super(debug)

    @node = record[:node]
    @area = record[:area]
    @process_id = record[:process_id]
    @active_interfaces = eval(record[:active_interfaces])
    @passive_interfaces = eval(record[:passive_interfaces])

    @ip_owners_table = table_of[:ip_owners]
    @routes_table = table_of[:routes]
  end
  # rubocop:enable Security/Eval

  # make as_area_table record
  # see: ASAreaTableRecord, ASAreaTable#make_as_area_table
  def as_area(asn)
    area, proc_id, if_infos = area_interfaces
    opts = {
      asn: asn, area: area, node: @node, process_id: proc_id,
      interfaces: if_infos, routes_table: @routes_table
    }
    ASAreaTableRecord.new(opts, @debug)
  end

  def to_s
    [
      "ConfigOSPFAreaTableRec: #{@area},#{@node},#{@process_id}",
      "act#{@active_interfaces},psv#{@passive_interfaces}"
    ].join(',')
  end

  private

  def make_interface_infos(interfaces)
    interfaces.map do |interface|
      ip_rec = @ip_owners_table.find_by_node_int(@node, interface)
      InterfaceInfo.new(interface, ip_rec)
    end
  end

  def area_interfaces
    interfaces = [@active_interfaces, @passive_interfaces].flatten
    [@area, @process_id, make_interface_infos(interfaces)]
  end
end

# config_ospf_area table
class ConfigOSPFAreaTable < TableBase
  extend Forwardable

  def_delegators :@records, :each, :find, :[]

  def initialize(target, table_of, debug = false)
    super(target, 'config_ospf_area.csv', debug)

    @records = @orig_table.map do |record|
      ConfigOSPFAreaTableRecord.new(record, table_of, debug)
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

  def to_s
    @records.map(&:to_s).join("\n").to_s
  end
end
