# frozen_string_literal: true

require 'forwardable'
require_relative 'table_base'

# row of ip_owners table
class IPOwnersTableRecord < TableRecordBase
  attr_accessor :ip, :mask, :node, :interface

  def initialize(record, debug = false)
    super(debug)

    @ip = record[:ip]
    @mask = record[:mask]
    @node = record[:node]
    @interface = record[:interface]
  end

  def make_interface_info
    { interface: @interface, ip: @ip, mask: @mask }
  end

  def ip_mask_str
    "#{@ip}/#{@mask}"
  end

  def to_s
    "#{@node}, #{@interface}, #{ip_mask_str}"
  end
end

# ip_owners table
class IPOwnersTable < TableBase
  extend Forwardable

  def_delegators :@records, :each, :find, :[]

  def initialize(target, debug = false)
    super(target, 'ip_owners.csv', debug)

    @records = @orig_table.map { |r| IPOwnersTableRecord.new(r, debug) }
  end

  def find_by_node_ip(node, ip)
    @records.find { |r| r.node == node && r.ip == ip }
  end

  def find_by_node_int(node, interface)
    @records.find { |r| r.node == node && r.interface == interface }
  end

  def find_interface(node, ip)
    data = find_by_node_ip(node, ip)
    data.nil? ? ip : data.interface
  end

  def find_interfaces(node)
    @records
      .find_all { |r| r.node == node }
      .map(&:make_interface_info)
  end

  def nodes
    @records.map(&:node).sort.uniq
  end

  def node_interfaces_table
    interfaces_of = {}
    nodes.each do |node|
      interfaces_of[node] = find_interfaces(node)
    end
    interfaces_of
  end
end
