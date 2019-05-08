require 'csv'
require 'netomox'
require_relative 'layer_base'

# rubocop:disable Metrics/ClassLength
# layer topology converter for batfish bgp network data
class BGPTopologyConverter < TopologyLayerBase
  def initialize(opts = {})
    super(opts)
    @edges_bgp_table = read_table('edges_bgp.csv')
    @config_bgp_proc_table = read_table('config_bgp_proc.csv')
    @config_ospf_area_table = read_table('config_ospf_area.csv')
    @ip_owners_table = read_table('ip_owners.csv')
    make_tables
  end

  def make_topology(nws)
    make_bgp_layer(nws)
    make_bgp_proc_layer(nws)
  end

  private

  def make_tables
    @as_numbers = @edges_bgp_table[:as_number].uniq
    debug '# as_numbers: ', @as_numbers
    @nodes_in_as = make_nodes_in_as
    debug '# nodes_in_as: ', @nodes_in_as
    @areas_in_as = make_areas_in_as
    debug '# areas_in_as: ', @areas_in_as
    @links_inter_as = make_links_inter_as
    debug '# links_inter_as: ', @links_inter_as
  end

  def find_interface(node, ip)
    data = @ip_owners_table.find do |row|
      row[:node] == node && row[:ip] == ip
    end
    data[:interface]
  end

  def make_bgp_proc_tp(node, edge)
    {
      node: node,
      ip: edge[:ip],
      interface: find_interface(node, edge[:ip])
    }
  end

  def find_edges(node, neighbor_ip)
    @edges_bgp_table.find do |row|
      row[:node] == node && row[:remote_ip] == neighbor_ip.gsub(%r{/\d+}, '')
    end
  end

  def ips_facing_neighbors(node, neighbors_list)
    neighbors = eval(neighbors_list)
    neighbors
      .map { |neighbor_ip| find_edges(node, neighbor_ip) }
      .delete_if(&:nil?)
      .map { |edge| make_bgp_proc_tp(node, edge) }
  end

  # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
  def make_bgp_proc_layer_nodes(nws)
    @config_bgp_proc_table.each do |row|
      prefixes = routes_of(row[:node], /.*bgp/)
      tps = ips_facing_neighbors(row[:node], row[:neighbors])
      debug "### check node:#{row[:node]}, " \
            "neighbors:#{row[:neighbors]}, tps:", tps

      nws.network('bgp-proc').register do
        node row[:router_id] do
          lo_count = -1
          tps.each do |tp|
            # NOTICE: for IGP, loopback interface connects multiple edges...
            tp_name = if tp[:interface] =~ /Loopback/i
                        lo_count += 1
                        lo_count > 0 ? "#{tp[:ip]}:#{lo_count}" : tp[:ip]
                      else
                        tp[:ip]
                      end
            # p "### check1, tp_name:#{tp_name}"
            term_point tp_name do
              support 'layer3', row[:node], tp[:interface]
            end
          end
          support 'layer3', row[:node]
          attribute(prefixes: prefixes, flags: ['bgp-proc'])
        end
      end
    end
  end
  # rubocop:enable Metrics/MethodLength, Metrics/AbcSize

  def count_tp_ref(key)
    @tp_ref_count[key] = -1 if @tp_ref_count[key].nil?
    @tp_ref_count[key] += 1
  end

  def counted_name(name, count)
    count > 0 ? "#{name}:#{count}" : name
  end

  def make_bgp_proc_link_param(node, ip)
    interface = find_interface(node, ip)
    {
      node: node,
      router_id: find_router_id(node),
      ip: ip,
      interface: interface,
      key: "#{node}-#{interface}"
    }
  end

  # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
  def make_bgp_proc_link_tp(row)
    src = make_bgp_proc_link_param(row[:node], row[:ip])
    dst = make_bgp_proc_link_param(row[:remote_node], row[:remote_ip])
    forward_key = "#{src[:key]}-#{dst[:key]}"
    reverse_key = "#{dst[:key]}-#{src[:key]}"

    debug "###### fwd_key=#{forward_key}, rev_key=#{reverse_key}"
    if @link_ref_count[forward_key].nil? && @link_ref_count[reverse_key].nil?
      count_tp_ref(src[:key])
      count_tp_ref(dst[:key])
      @link_ref_count[forward_key] = [
        @tp_ref_count[src[:key]], @tp_ref_count[dst[:key]]
      ]
      debug "### rev/fwd not found, #{@link_ref_count[forward_key]}"
    elsif @link_ref_count[forward_key].nil? # exists reverse
      @link_ref_count[forward_key] = @link_ref_count[reverse_key].reverse
      debug "### rev found (fwd not found), #{@link_ref_count[forward_key]}"
    else
      warn 'WARNING: duplicated link?'
    end

    src[:ip] = counted_name(src[:ip], @link_ref_count[forward_key][0])
    dst[:ip] = counted_name(dst[:ip], @link_ref_count[forward_key][1])

    # debug "### check2, tp_ref_count: ", @tp_ref_count
    # debug "### check2, link_ref_count: ", @link_ref_count
    debug "### src: #{src[:node]}, #{src[:ip]}, #{src[:interface]}"
    debug "### dst: #{dst[:node]}, #{dst[:ip]}, #{dst[:interface]}"
    [src, dst]
  end
  # rubocop:enable Metrics/MethodLength, Metrics/AbcSize

  def make_bgp_proc_layer_links(nws)
    # TODO
    @tp_ref_count = {}
    @link_ref_count = {}
    @edges_bgp_table.each do |row|
      src, dst = make_bgp_proc_link_tp(row)
      nws.network('bgp-proc').register do
        link src[:router_id], src[:ip], dst[:router_id], dst[:ip]
      end
    end
  end

  def make_bgp_proc_layer(nws)
    nws.register do
      network 'bgp-proc' do
        type Netomox::NWTYPE_L3
      end
    end
    make_bgp_proc_layer_nodes(nws)
    make_bgp_proc_layer_links(nws)
  end

  # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
  def make_bgp_layer_nodes(nws)
    @as_numbers.each do |asn|
      tps = interfaces_inter_as(asn)
      # p "### check: AS:#{asn}, tps:", tps
      areas = @areas_in_as[asn]
      router_ids = router_ids_in_as(asn)

      nws.network('bgp').register do
        # AS as node
        node "as#{asn}" do
          # interface of inter-AS link and its support-tp
          tps.each do |tp|
            term_point tp[:interface] do
              support 'bgp-proc', tp[:router_id], tp[:interface]
            end
          end
          # support-node to ospf layer
          areas.each do |area|
            support 'ospf', "as#{asn}-area#{area}"
          end
          # support-node to bgp-proc layer
          router_ids.each do |router_id|
            support 'bgp-proc', router_id
          end
        end
      end
    end
  end
  # rubocop:enable Metrics/MethodLength, Metrics/AbcSize

  def make_bgp_layer_links(nws)
    @links_inter_as.each do |link_row|
      src = link_row[:source]
      dst = link_row[:destination]
      nws.network('bgp').register do
        link "as#{src[:as]}", src[:interface], "as#{dst[:as]}", dst[:interface]
      end
    end
  end

  def make_bgp_layer(nws)
    nws.register { network 'bgp' }
    make_bgp_layer_nodes(nws)
    make_bgp_layer_links(nws)
  end

  def router_ids_in_as(asn)
    @nodes_in_as[asn].map { |node| find_router_id(node) }
  end

  def interfaces_inter_as(asn)
    @links_inter_as
      .find_all { |link| link[:source][:as] == asn }
      .map { |link| link[:source] }
  end

  def find_router_id(node)
    data = @config_bgp_proc_table.find { |row| row[:node] == node }
    # NOTICE: assume single process in node
    #   bgp_proc_table has only "neighbor ip list" (destination ip list)
    data[:router_id]
  end

  def make_as_link_tp(asn, node, interface)
    {
      as: asn, node: node, interface: interface,
      router_id: find_router_id(node)
    }
  end

  def make_as_link(link)
    {
      source: make_as_link_tp(
        link[:as_number], link[:node], link[:ip]
      ),
      destination: make_as_link_tp(
        link[:remote_as_number], link[:remote_node], link[:remote_ip]
      )
    }
  end

  def make_links_inter_as
    @edges_bgp_table
      .find_all { |row| row[:as_number] != row[:remote_as_number] }
      .map { |link| make_as_link(link) }
  end

  def find_nodes_in(asn)
    @edges_bgp_table
      .find_all { |row| row[:as_number] == asn }
      .map { |row| row[:node] }
      .sort.uniq
  end

  def make_nodes_in_as
    nodes_in_as = {}
    @as_numbers.each do |asn|
      nodes_in_as[asn] = find_nodes_in(asn)
    end
    nodes_in_as
  end

  def find_areas(nodes)
    areas = nodes.map do |node|
      @config_ospf_area_table
        .find_all { |row| row[:node] == node }
        .map { |row| row[:area] }
    end
    areas.flatten.sort.uniq
  end

  def make_areas_in_as
    areas_in_as = {}
    @nodes_in_as.each_pair do |asn, nodes|
      areas_in_as[asn] = find_areas(nodes)
    end
    areas_in_as
  end
end
# rubocop:enable Metrics/ClassLength
