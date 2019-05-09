require 'csv'
require 'netomox'
require_relative 'layer_base'

# rubocop:disable Metrics/ClassLength
# layer topology converter for batfish ospf network data
class OSPFTopologyConverter < TopologyLayerBase
  def initialize(opts = {})
    super(opts)
    @edges_bgp_table = read_table('edges_bgp.csv')
    @config_ospf_area_table = read_table('config_ospf_area.csv')
    @edges_ospf_table = read_table('edges_ospf.csv')
    @ip_owners_table = read_table('ip_owners.csv')
    make_tables
  end

  def make_topology(nws)
    make_ospf_area_layer(nws)
    make_ospf_proc_layer(nws)
  end

  private

  def make_tables
    @as_numbers = @edges_bgp_table[:as_number].uniq
    debug '# as_numbers: ', @as_numbers
    @nodes_in_as = find_nodes_in_as
    debug '# nodes_in_as:', @nodes_in_as
    @as_area_table = make_as_area_table
    debug '# as_area_table: ', @as_area_table
    @links = make_ospf_links
    debug '# ospf_link (edges)', @links
  end

  # rubocop:disable Metrics/MethodLength
  def make_ospf_area_layer_nodes(nws)
    @as_numbers.each do |asn|
      debug "# areas in #{asn} -- #{areas_in_as(asn)}"
      areas_in_as(asn).each do |area|
        support_nodes = nodes_in(asn, area)
        debug "## asn,area = #{asn}, #{area}"
        debug support_nodes
        nws.network('ospf').register do
          node "as#{asn}-area#{area}" do
            # TODO: term point (inter ospf area)
            # support node
            support_nodes.each do |support_node|
              support 'ospf-proc', support_node
            end
          end
          # TODO: link (inter ospf area)
        end
      end
    end
  end
  # rubocop:enable Metrics/MethodLength

  def make_ospf_area_layer(nws)
    nws.register { network 'ospf' }
    make_ospf_area_layer_nodes(nws)
  end

  # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
  def make_ospf_proc_layer_nodes(nws)
    @as_area_table.select { |row| row[:area] >= 0 }.each do |row|
      prefixes = routes_of(row[:node], /ospf.*/)
      nws.network('ospf-proc').register do
        node row[:node] do
          # tp
          row[:interfaces].each do |tp|
            term_point tp[:interface] do
              support 'layer3', row[:node], tp[:interface]
              attribute(ip_addrs: [tp[:ip]])
            end
          end
          # support-node
          support 'layer3', row[:node]
          attribute(
            name: "process_#{row[:process_id]}",
            prefixes: prefixes,
            flags: ['ospf-proc']
          )
        end
        # TODO: link (inter ospf proc)
      end
    end
  end
  # rubocop:enable Metrics/MethodLength, Metrics/AbcSize

  def make_ospf_proc_layer_links(nws)
    @links.each do |link_row|
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

  def areas_in_as(asn)
    @as_area_table
      .find_all { |row| row[:as] == asn }
      .map { |row| row[:area] }
      .find_all { |area| area > 0 }
      .sort.uniq
  end

  def nodes_in(asn, area)
    @as_area_table
      .find_all { |row| row[:as] == asn && row[:area] == area }
      .map { |row| row[:node] }
      .sort.uniq
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

  def find_ospf_config(node)
    @config_ospf_area_table.find { |row| row[:node] == node }
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

  def make_as_area_row(asn, area, node, proc_id, interfaces)
    {
      as: asn,
      area: area,
      node: node,
      process_id: proc_id,
      interfaces: interfaces
    }
  end

  def make_as_area_table
    as_area_table = []
    @nodes_in_as.each_pair do |asn, nodes|
      nodes.each do |node|
        config = find_ospf_config(node)
        area, proc_id, interfaces = get_area_interface_from(config)
        as_area = make_as_area_row(asn, area, node, proc_id, interfaces)
        as_area_table.push(as_area)
      end
    end
    as_area_table
  end

  def separate_node_interface(node_interface)
    /(.+)\[(.+)\]/.match(node_interface).captures
  end

  def interface_names(as_area_row)
    as_area_row[:interfaces].map {|if_info| if_info[:interface] }
  end

  def make_tp_info_from(node, term_point)
    found_row = @as_area_table.find do |row|
      row[:node] == node && interface_names(row).include?(term_point)
    end
    # TODO: if not found?
    {
      as: found_row[:as],
      area: found_row[:area],
      node: node,
      interface: term_point
    }
  end

  def make_ospf_link_info(node_interface)
    node, tp = separate_node_interface(node_interface)
    make_tp_info_from(node, tp)
  end

  def make_ospf_links
    @edges_ospf_table.map do |row|
      src = make_ospf_link_info(row[:interface])
      dst = make_ospf_link_info(row[:remote_interface])
      { source: src, destination: dst }
    end
  end
end
# rubocop:enable Metrics/ClassLength
