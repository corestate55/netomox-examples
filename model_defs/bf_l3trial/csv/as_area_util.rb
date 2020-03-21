# frozen_string_literal: true

require_relative 'table_base'

# interfaces infomation for ASAreaTableRecord
# A part of ASAreaTableRecord.
class InterfaceInfo
  attr_accessor :interface, :ip

  def initialize(interface, ip_rec)
    @interface = interface
    @ip = ip_rec.ip_mask_str
  end

  def to_s
    "IfInfo:#{@interface},#{@ip}"
  end
end

# record of as_area table.
# generated from config_ospf_area table
class ASAreaTableRecord < TableRecordBase
  attr_accessor :as, :area, :node, :process_id, :interfaces
  def initialize(opts, debug = false)
    super(debug)

    @as = opts[:asn]
    @area = opts[:area]
    @node = opts[:node]
    @process_id = opts[:process_id]
    @interfaces = opts[:interfaces] # Array of InterfaceInfo instance

    @routes_table = opts[:routes_table]
  end

  def ospf_proc_node_attribute
    {
      name: "process_#{@process_id}",
      prefixes: @routes_table.routes_ospf_proc(@node),
      flags: ['ospf-proc']
    }
  end

  def to_s
    ints_str = @interfaces.map(&:to_s).join(',')
    "ASAreaTableRecord: #{@as},#{@area},#{@node},#{@process_id},[#{ints_str}]"
  end
end
