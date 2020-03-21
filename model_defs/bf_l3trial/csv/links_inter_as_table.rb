# frozen_string_literal: true

require 'forwardable'
require_relative 'table_base'

# utility for Inter-BGP-AS links edge (term-point)
# see: BGPEdge#as_link_tp
class ASLinkTp
  attr_accessor :as, :node, :interface, :router_id

  def initialize(asn, router_id, node, interface)
    @as = asn
    @router_id = router_id
    @node = node
    @interface = interface
  end

  def to_s
    "ASLinkTp:#{@as},#{@router_id},#{@node},#{@interface}"
  end
end

# record (link) inter BGP-AS
# see: EdgesBGPTableRecord#make_as_link <= EdgesBGPTable#make_links_inter_as
class LinksInterASTableRecord < TableRecordBase
  attr_accessor :src, :dst

  # src and dst are BGPEdge instance
  def initialize(src, dst, debug = false)
    super(debug)

    @src = src.as_link_tp # returns ASLinkTp instance
    @dst = dst.as_link_tp
  end

  def to_s
    "LinksInterASTableRecord: src=#{@src}, dst=#{@dst}"
  end
end

# Links inter BGP-AS table (for bgp-as topology)
class LinksInterASTable < TableBase
  extend Forwardable

  def_delegators :@records, :each, :find, :[]

  def initialize(target, table_of, debug = false)
    super(target, nil, debug)

    # @records: Array of LinksInterASTableRecords
    @records = table_of[:edges_bgp].make_links_inter_as
  end

  def interfaces_inter_as(asn)
    @records
      .find_all { |link| link.src.as == asn }
      .map(&:src)
  end

  def to_s
    @records.map(&:to_s).join("\n").to_s
  end
end
