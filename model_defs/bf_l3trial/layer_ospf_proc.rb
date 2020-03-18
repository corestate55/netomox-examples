# frozen_string_literal: true

require 'netomox'
require_relative 'layer_ospf_base'

# rubocop:disable Metrics/ClassLength
# ospf-proc layer topology converter
class OSPFProcTopologyConverter < OSPFTopologyConverterBase
  def initialize(opts = {})
    super(opts)
    @edges_ospf_table = read_table('edges_ospf.csv')
    make_tables
  end

  def make_topology(nws)
    make_ospf_proc_layer(nws)
  end

  private

  def make_tables
    super
    @proc_links = make_ospf_proc_links
    debug '# ospf_proc_link (edges): ', @proc_links
  end

  def separate_node_interface(node_interface)
    /(.+)\[(.+)\]/.match(node_interface).captures
  end

  def interface_names(as_area_row)
    as_area_row[:interfaces].map { |if_info| if_info[:interface] }
  end

  # rubocop:disable Metrics/MethodLength
  def make_tp_info_from(node, term_point)
    found_row = @as_area_table.find do |row|
      row[:node] == node && interface_names(row).include?(term_point)
    end
    if found_row
      {
        as: found_row[:as],
        area: found_row[:area],
        node: node,
        interface: term_point
      }
    else
      {
        as: -1,
        area: -1,
        node: node,
        interface: term_point
      }
    end
  end
  # rubocop:enable Metrics/MethodLength

  def make_ospf_link_info(node_interface)
    node, tp = separate_node_interface(node_interface)
    make_tp_info_from(node, tp)
  end

  def make_ospf_proc_links
    links = @edges_ospf_table.map do |row|
      src = make_ospf_link_info(row[:interface])
      dst = make_ospf_link_info(row[:remote_interface])
      { source: src, destination: dst }
    end
    links.filter do |link|
      link[:source][:as] >= 0 && link[:destination][:as] >= 0
    end
  end

  def ospf_proc_node_attribute(row)
    {
      name: "process_#{row[:process_id]}",
      prefixes: routes_of(row[:node], /ospf.*/),
      flags: ['ospf-proc']
    }
  end

  # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
  def make_ospf_proc_layer_nodes(nws)
    support_count = {}
    @as_area_table
      .select { |row| row[:area] >= 0 }
      .each do |row|
      debug '# ospf_layer node: ', row

      node_attr = ospf_proc_node_attribute(row)
      nws.network('ospf-proc').register do
        node row[:node] do
          # tp
          row[:interfaces].each do |tp|
            term_point tp[:interface] do
              support 'layer3', row[:node], tp[:interface]
              attribute(ip_addrs: [tp[:ip]])
            end
          end
          # avoid duplicate support-node
          key = "#{row[:as]}-#{row[:node]}"
          support_count[key] = support_count[key] || 0
          if support_count[key] < 1
            support 'layer3', row[:node]
            attribute(node_attr)
          end
          support_count[key] += 1
        end
      end
    end
  end
  # rubocop:enable Metrics/MethodLength, Metrics/AbcSize

  def make_ospf_proc_layer_links(nws)
    @proc_links.each do |link_row|
      src = link_row[:source]
      dst = link_row[:destination]
      nws.network('ospf-proc').register do
        link src[:node], src[:interface], dst[:node], dst[:interface]
      end
    end
  end

  def make_ospf_proc_layer(nws)
    nws.register do
      network 'ospf-proc' do
        type Netomox::NWTYPE_L3
      end
    end
    make_ospf_proc_layer_nodes(nws)
    make_ospf_proc_layer_links(nws)
  end
end
# rubocop:enable Metrics/ClassLength
