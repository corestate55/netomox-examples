# frozen_string_literal: true

require 'forwardable'
require_relative 'table_base'

# row of interface-properties table
class InterfacePropertiesTableRecord < TableRecordBase
  attr_accessor :node, :interface, :vrf, :mtu, :access_vlan, :allowed_vlans,
                :switchport, :switchport_mode, :switchport_encap

  def initialize(record)
    super()
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

  def vlan_range_to_array(range_str)
    if range_str =~ /(\d+)-(\d+)/
      md = Regexp.last_match
      return (md[1].to_i..md[2].to_i).to_a
    end

    range_str.to_i
  end

  def parse_allowed_vlans(vlans_str)
    # string to array
    case vlans_str
    when /^\d+$/
      # single number
      [vlans_str.to_i]
    when /^\d+-\d+$/
      # single range
      vlan_range_to_array(vlans_str)
    when /,/
      # multiple numbers and ranges
      vlans_str.split(',').map { |str| vlan_range_to_array(str) }.flatten
    else
      []
    end
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
