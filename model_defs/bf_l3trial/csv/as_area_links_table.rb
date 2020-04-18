# frozen_string_literal: true

require_relative 'table_base'

# edge (term-point) of AS-Are link
class ASAreaLinkEdge
  attr_accessor :node, :tp

  def initialize(node, term_point)
    @node = node
    @tp = term_point
  end

  def to_s
    "ASAreaLinkEdge: #{@node},#{@tp}"
  end
end

# AS-Area links table record
class ASAreaLinkTableRecord < TableRecordBase
  attr_accessor :as, :node, :node_tp, :area, :area_tp,
                :src, :dst

  # see ASAreaTable#makeOSPFAreaLinks
  def initialize(area_node_pair, interface, area_tp_count)
    @as = area_node_pair.as
    @node = area_node_pair.node
    @node_tp = interface.interface
    @area = area_node_name(area_node_pair.as, area_node_pair.area)
    @area_tp = "p#{area_tp_count}"

    # alias
    @src = ASAreaLinkEdge.new(@node, @node_tp)
    @dst = ASAreaLinkEdge.new(@area, @area_tp)
  end

  def as_node_key
    "#{@as}-#{@node}"
  end

  def to_s
    "ASAreaLinkTableRec: #{@as},#{@node},#{@node_tp},#{@area},#{@area_tp}"
  end

  private

  # name of ospf-are node in ospf-area layer
  def area_node_name(asn, area)
    "as#{asn}-area#{area}"
  end
end

# AS-Area link table
class ASAreaLinkTable < TableBase
  extend Forwardable

  def_delegators :@records, :each, :find, :[]

  def initialize(target, table_of, debug = false)
    super(target, nil, debug)
    @records = table_of[:as_area].make_ospf_area_links
  end

  def to_s
    @records.map(&:to_s).join("\n").to_s
  end
end
