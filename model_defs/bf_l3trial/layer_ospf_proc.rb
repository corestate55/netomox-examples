# frozen_string_literal: true

require 'netomox'
require_relative 'layer_ospf_base'
require_relative 'csv/edges_ospf_table'

# ospf-proc layer topology converter
class OSPFProcTopologyConverter < OSPFTopologyConverterBase
  def initialize(opts = {})
    super(opts)

    # @edges_ospf_table uses @as_area_table,
    # put after super.make_tables (@as_area_table)
    table_of = { as_area: @as_area_table }
    @edges_ospf_table = EdgesOSPFTable.new(@target, table_of)
  end

  def make_topology(nws)
    make_ospf_proc_layer(nws)
  end

  private

  # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
  def make_ospf_proc_layer_nodes(layer_ospf_proc)
    support_count = {}
    @as_area_table.records_has_area.each do |rec|
      debug '# ospf_layer node: ', rec

      node_attr = rec.ospf_proc_node_attribute
      layer_ospf_proc.node(rec.node) do
        # tp
        rec.interfaces.each do |tp|
          term_point tp.interface do
            support 'layer3', rec.node, tp.interface
            attribute(ip_addrs: [tp.ip])
          end
        end
        # avoid duplicate support-node
        key = "#{rec.as}-#{rec.node}"
        support_count[key] = support_count[key] || 0
        if support_count[key] < 1
          support 'layer3', rec.node
          attribute(node_attr)
        end
        support_count[key] += 1
      end
    end
  end
  # rubocop:enable Metrics/MethodLength, Metrics/AbcSize

  def make_ospf_proc_layer_links(layer_ospf_proc)
    @edges_ospf_table.proc_links.each do |p_link|
      layer_ospf_proc.register do
        link p_link.src.node, p_link.src.interface,
             p_link.dst.node, p_link.dst.interface
      end
    end
  end

  def make_ospf_proc_layer(nws)
    nws.register do
      network 'ospf-proc' do
        type Netomox::NWTYPE_L3
      end
    end
    layer_ospf_proc = nws.network('ospf-proc')
    make_ospf_proc_layer_nodes(layer_ospf_proc)
    make_ospf_proc_layer_links(layer_ospf_proc)
  end
end
