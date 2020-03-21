# frozen_string_literal: true

require_relative 'links_inter_as_table'

# edge (term-point) of inter bgp-proc link
class BGPEdge
  attr_accessor :node, :ip, :as_number, :router_id, :interface, :key

  def initialize(node, ip, as_number, router_id, interface)
    @node = node
    @ip = ip
    @as_number = as_number
    @router_id = router_id # additional
    @interface = interface # additional
    @key = key_str # additional
  end

  def as_link_tp
    ASLinkTp.new(@as_number, @router_id, @node, @ip)
  end

  def save_counted_ip(count)
    @ip = count.positive? ? "#{ip}:#{count}" : ip
  end

  def to_s
    "BGPEdge:#{@node},#{@ip},#{@as_number},#{@router_id},#{@interface}"
  end

  private

  def key_str
    "#{@node}-#{@interface}"
  end
end

# tp-ref counter
class ProcTpRefCounter
  def initialize
    @ref_count = {}
  end

  def count_of(edge)
    # edge -> BGPProcLinkTermPoint instance
    @ref_count[edge.key] = -1 if @ref_count[edge.key].nil?
    @ref_count[edge.key] += 1
  end

  def [](edge)
    @ref_count[edge.key]
  end
end

# link-ref count memory
class ProcLinkRefCounter
  def initialize
    @ref_count = {}
  end

  def count_of(key, src_count, dst_count)
    @ref_count[key] = [src_count, dst_count]
  end

  def [](key)
    @ref_count[key]
  end
end
