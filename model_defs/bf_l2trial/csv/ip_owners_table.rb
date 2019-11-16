# frozen_string_literal: true

require 'forwardable'
require_relative 'table_base'

# row of ip-owners table
class IPOwnersTableRecord < TableRecordBase
  attr_accessor :node, :vrf, :interface, :ip, :mask, :active

  def initialize(record)
    @node = record[:node]
    @vrf = record[:vrf]
    @interface = record[:interface]
    @ip = record[:ip]
    @mask = record[:mask]
    @active = record[:active]
  end

  def physical_interface?
    @interface !~ /Vlan*/
  end

  def node_name_by_device_type(is_host)
    is_host ? @node : routing_instance_name
  end

  def l2node_name
    if @interface =~ /Vlan(\d+)/ # TODO: L2-L3 mapping
      vlan_id = Regexp.last_match(1)
      "#{@node}_VL#{vlan_id}"
    else
      @node
    end
  end

  private

  def routing_instance
    @vrf == 'default' ? 'GRT' : @vrf
  end

  def routing_instance_name
    "#{@node}-#{routing_instance}"
  end
end

# ip-owners table
class IPOwnersTable < TableBase
  extend Forwardable

  def_delegators :@records, :each, :find, :[]

  def initialize(target)
    super(target, 'ip_owners.csv')
    @records = @orig_table.map { |r| IPOwnersTableRecord.new(r) }
  end

  def find_node_int(node, interface)
    @records.find { |r| r.node == node && r.interface == interface }
  end
end
