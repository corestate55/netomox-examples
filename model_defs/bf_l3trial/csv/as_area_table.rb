# frozen_string_literal: true

require 'forwardable'
require_relative 'table_base'
require_relative 'as_area_links_table'

# record of as_area table.
class ASAreaTableRecord < TableRecordBase
  attr_accessor :as, :area, :node, :process_id, :router_id, :interfaces, :areas

  def initialize(opts, debug = false)
    super(debug)

    @as = opts[:asn]
    @area = opts[:area]
    @node = opts[:node]
    @process_id = opts[:process_id]
    @router_id = opts[:router_id]
    @areas = opts[:areas] # Array of areas in the ospf processf
    @interfaces = opts[:interfaces] # Array of InterfaceInfo instance

    @routes_table = opts[:routes_table]
  end

  def ospf_proc_node_attribute
    {
      name: "process_#{@process_id}",
      router_id: @router_id,
      prefixes: @routes_table.routes_ospf_proc(@node),
      flags: ['ospf-proc', "areas=#{@areas.join('/')}"]
    }
  end

  def to_s
    ints_str = @interfaces.map(&:to_s).join(',')
    "ASAreaTableRecord: #{@as},#{@area},#{@node},#{@process_id},#{@router_id},[#{ints_str}]"
  end
end

# BGP-AS--OSPF-Area table
class ASAreaTable < TableBase
  extend Forwardable

  def_delegators :@records, :each, :find, :[]

  def initialize(target, table_of, debug = false)
    super(target, nil, debug)

    @as_numbers = table_of[:as_numbers]
    @edges_bgp_table = table_of[:edges_bgp]
    @config_ospf_area_table = table_of[:config_ospf_area]

    nodes_in_as = find_nodes_in_as
    debug '# nodes_in_as:', nodes_in_as

    # NOTICE: @records is NOT array, it is Hash
    # key:AS-Number => value:ASAreaTableRecord
    @records = make_as_area_table(nodes_in_as)
  end

  def nodes_in(asn, area)
    @records
      .find_all { |r| r.as == asn && r.area == area }
      .map(&:node)
      .sort
      .uniq
  end

  def areas_in_as(asn)
    @records
      .find_all { |r| r.as == asn }
      .map(&:area)
      .find_all { |area| area >= 0 } # area 0 MUST be backbone area.
      .sort
      .uniq
  end

  def records_has_area
    @records.select { |r| r.area >= 0 }
  end

  # rubocop:disable Metrics/MethodLength
  def make_ospf_area_links
    # find router and its interface that connects multiple-area
    area_node_pairs = area_node_connections
    count_area_tp = {}
    links = area_node_pairs.flatten.map do |area_node_pair|
      area_node_pair.interfaces.map do |interface|
        area_key = node_pair_path(area_node_pair.as, area_node_pair.area)
        count_area_tp[area_key] = count_area_tp[area_key] || 0
        count_area_tp[area_key] += 1
        ASAreaLinkTableRecord.new(area_node_pair, interface,
                                  count_area_tp[area_key])
      end
    end
    links.flatten
  end
  # rubocop:enable Metrics/MethodLength

  def find_all_by_as_node(asn, node)
    @records.find_all { |r| r.as == asn && r.node == node }
  end

  def to_s
    @records.map(&:to_s).join("\n").to_s
  end

  private

  def area_node_connections
    inter_area_nodes.map do |as_node|
      find_all_by_as_node(as_node[:as], as_node[:node])
    end
  end

  def node_pair_path(node1, node2)
    "#{node1}__#{node2}"
  end

  def select_duplicated_paths
    paths = @records.map { |r| node_pair_path(r.as, r.node) }
    paths
      .sort
      .reject { |p| paths.index(p) == paths.rindex(p) } # reject single element
      .uniq
  end

  def split_node_pair_path(as_node_path)
    /(.*)__(.*)/.match(as_node_path).captures
  end

  def inter_area_nodes
    select_duplicated_paths.map do |as_node_path|
      as, node = split_node_pair_path(as_node_path)
      { as: as.to_i, node: node }
    end
  end

  def find_nodes_in_as
    nodes_in_as = {}
    @as_numbers.each do |asn|
      edges_in_as = @edges_bgp_table.find_all_by_as(asn)
      # edges (links) is a pair of 2-unidirectional rows for one link
      nodes_in_as[asn] = edges_in_as.map { |e| e.src.node }.sort.uniq
    end
    nodes_in_as
  end

  def make_as_area_table(nodes_in_as)
    as_area_table = []
    # Combine data: AS -> Node (in AS) -> OSPF Area/Proc
    nodes_in_as.each_pair do |asn, nodes|
      nodes.each do |node|
        @config_ospf_area_table.find_all_by_node(node).each do |record|
          opts = record.as_area(asn)
          as_area_table.push(ASAreaTableRecord.new(opts, @debug))
        end
      end
    end
    as_area_table
  end
end
