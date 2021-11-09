# frozen_string_literal: true

require 'csv'

# Base class for csv-wrapper
class TableBase
  def initialize(target, table_file)
    csv_dir = "model_defs/mddo_trial/csv/#{target}"
    @orig_table = CSV.table("#{csv_dir}/#{table_file}")
  end
end

# Base class for record of csv-wrapper
class TableRecordBase
  # get multiple method-results
  def values(attrs)
    attrs.map { |attr| send(attr) }
  end
end

# Base class of edges-table endpoint
class EdgeBase < TableRecordBase
  attr_accessor :node, :interface

  def self.generate(node, interface)
    EdgeBase.new("#{node}[#{interface}]")
  end

  def initialize(interface_str)
    super()
    interface_str =~ /(.+)\[(.+)\]/
    @node = Regexp.last_match(1)
    @interface = Regexp.last_match(2)
  end

  def physical_interface?
    @interface !~ /Vlan*/
  end

  def ==(other)
    @node == other.node && @interface == other.interface
  end

  def to_s
    "#{@node}[#{@interface}]"
  end
end

# make layer2 segment name (per device)
def l2node_name(node_name, vlan_id)
  "#{node_name}_VL#{vlan_id}"
end

# make layer3 segment name
def l3seg_node_name(vlan_id)
  "Seg-VL#{vlan_id}"
end
