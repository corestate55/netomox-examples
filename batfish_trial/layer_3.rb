require 'csv'
require 'netomox'
require_relative 'layer_base'

class Layer3TopologyConverter < TopologyLayerBase
  def initialize(opts={})
    super(opts)
    @edges_layer3_table = read_table('csv/edges_layer3.csv')
    @ip_owners_table = read_table('csv/ip_owners.csv')
    make_tables
  end

  def make_topology(nws)
    make_layer3_layer(nws)
  end

  private

  def make_tables
    @node_interfaces_table = make_node_interfaces_table
    debug '# node_interfaces_table: ', @node_interfaces_table
    @links = make_layer3_links
    debug '# links: ', @links
  end

  def make_layer3_layer_nodes(nws)
    @node_interfaces_table.each_pair do |node, interfaces|
      nws.network('layer3').register do
        node node do
          interfaces.each do |tp|
            term_point tp[:interface] do
              attribute(ip_addrs: ["#{tp[:ip]}/#{tp[:mask]}"])
            end
          end
        end
      end
    end
  end

  def make_layer3_layer_links(nws)
    @links.each do |link_row|
      src = link_row[:source]
      dst = link_row[:destination]
      nws.network('layer3').register do
        link src[:node], src[:interface], dst[:node], dst[:interface]
      end
    end
  end

  def make_layer3_layer(nws)
    nws.register do
      network 'layer3' do
        type Netomox::NWTYPE_L3
      end
    end
    make_layer3_layer_nodes(nws)
    make_layer3_layer_links(nws)
  end

  def make_interface_info(interface, ip, mask)
    { interface: interface, ip: ip, mask: mask}
  end

  def find_interfaces(node)
    @ip_owners_table
      .find_all { |row| row[:node] == node }
      .map { |row| make_interface_info(row[:interface], row[:ip], row[:mask]) }
  end

  def make_node_interfaces_table
    nodes = @ip_owners_table.map { |row| row[:node] }.sort.uniq
    node_interfaces_table = {}
    nodes.each do |node|
      node_interfaces_table[node] = find_interfaces(node)
    end
    node_interfaces_table
  end

  def make_layer3_links
    @edges_layer3_table.map do |row|
      src = make_l3_link_info(row[:interface], row[:ips])
      dst = make_l3_link_info(row[:remote_interface], row[:remote_ips])
      { source: src, destination: dst }
    end
  end

  def separate_node_interface(node_interface)
    /(.+)\[(.+)\]/.match(node_interface).captures
  end

  def make_l3_link_info(node_interface, ips)
    node, tp = separate_node_interface(node_interface)
    ips = eval(ips) # ip list
    { node: node, interface: tp, ips: ips}
  end
end
