# frozen_string_literal: true

require 'csv'
require_relative 'layer_base'

# layer topology converter for batfish ospf network data
class OSPFTopologyConverterBase < TopologyLayerBase
  def initialize(opts = {})
    super(opts)
    @config_ospf_area_table = read_table('config_ospf_area.csv')
    @edges_bgp_table = read_table('edges_bgp.csv')
    @ip_owners_table = read_table('ip_owners.csv')
  end

  def make_topology(_nws)
    raise 'Abstract method must be override.'
  end

  private

  def make_tables
    @as_numbers = @edges_bgp_table[:as_number].uniq
    debug '# as_numbers: ', @as_numbers
    @nodes_in_as = find_nodes_in_as
    debug '# nodes_in_as:', @nodes_in_as
    @as_area_table = make_as_area_table
    debug '# as_area_table: ', @as_area_table
  end

  def find_nodes_in_as
    nodes_in_as = {}
    @as_numbers.each do |asn|
      rows_in_as = @edges_bgp_table.find_all { |row| row[:as_number] == asn }
      # edges (links) is a pair of 2-unidirectional rows for one link
      nodes_in_as[asn] = rows_in_as.map { |row| row[:node] }.sort.uniq
    end
    nodes_in_as
  end

  def find_all_ospf_config(node)
    @config_ospf_area_table.find_all { |row| row[:node] == node }
  end

  def find_interface(node, interface)
    @ip_owners_table.find do |row|
      row[:node] == node && row[:interface] == interface
    end
  end

  def make_interface_info(node, interfaces)
    interfaces.map do |interface|
      if_data = find_interface(node, interface)
      {
        interface: interface,
        ip: "#{if_data[:ip]}/#{if_data[:mask]}"
      }
    end
  end

  # rubocop:disable Security/Eval
  def get_area_interface_from(row)
    if row.nil?
      [-1, -1, []] # ospf area does not exists
    else
      interfaces = [eval(row[:active_interfaces]),
                    eval(row[:passive_interfaces])].flatten
      if_info = make_interface_info(row[:node], interfaces)
      [row[:area], row[:process_id], if_info]
    end
  end
  # rubocop:enable Security/Eval

  def make_as_area_row(asn, area, node, proc_id, interfaces)
    {
      as: asn,
      area: area,
      node: node,
      process_id: proc_id,
      interfaces: interfaces
    }
  end

  # rubocop:disable Metrics/MethodLength
  def make_as_area_table
    as_area_table = []
    @nodes_in_as.each_pair do |asn, nodes|
      nodes.each do |node|
        configs = find_all_ospf_config(node)
        configs.each do |config|
          area, proc_id, interfaces = get_area_interface_from(config)
          as_area = make_as_area_row(asn, area, node, proc_id, interfaces)
          as_area_table.push(as_area)
        end
      end
    end
    as_area_table
  end
  # rubocop:enable Metrics/MethodLength
end
