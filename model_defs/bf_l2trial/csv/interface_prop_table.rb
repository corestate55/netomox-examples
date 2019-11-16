# frozen_string_literal: true

require 'forwardable'
require_relative 'table_base'

# row of interface-properties table
class InterfacePropertiesTableRecord < TableRecordBase
  attr_accessor :node, :interface, :vrf, :mtu, :access_vlan, :allowed_vlans,
                :switchport, :switchport_mode, :switchport_encap

  # rubocop:disable Metrics/AbcSize
  def initialize(record)
    interface = EdgeBase.new(record[:interface])
    @node = interface.node
    @interface = interface.interface

    @access_vlan = record[:access_vlan]
    @allowed_vlans = parse_allowed_vlans(record[:allowed_vlans])
    @switchport = record[:switchport]
    @switchport_mode = record[:switchport_mode]
    @switchport_encap = record[:switchport_trunk_encapsulation]
    @mtu = record[:mtu]
    @vrf = record[:vrf]
  end
  # rubocop:enable Metrics/AbcSize

  def switchport?
    @switchport =~ /TRUE/i
  end

  def swp_access?
    switchport? && @switchport_mode =~ /ACCESS/i
  end

  def swp_trunk?
    switchport? && @switchport_mode =~ /TRUNK/i
  end

  def swp_vlans
    return [] unless switchport?

    swp_access? ? [@access_vlan] : @allowed_vlans
  end

  def swp_has_vlan?(vlan_id)
    swp_vlans.include?(vlan_id)
  end

  private

  def parse_allowed_vlans(vlans_str)
    vlans_str ? vlans_str.split(',').map(&:to_i) : [] # string to array
  end
end

# interface-properties table
class InterfacePropertiesTable < TableBase
  extend Forwardable

  def_delegators :@records, :each, :find, :[]

  def initialize(target)
    super(target, 'interface_props.csv')
    @records = @orig_table.map { |r| InterfacePropertiesTableRecord.new(r) }
  end

  def find_node_int(node, interface)
    @records.find { |r| r.node == node && r.interface == interface }
  end
end
