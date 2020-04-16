# frozen_string_literal: true

require_relative 'table_base'

# half of inter-area link
class ASAreaLink
  attr_accessor :as, :area, :node, :node_tp, :tp_count

  # see ASAreaTable#makeOSPFAreaLinks
  def initialize(asn, area, node, interface)
    @as = asn
    @area = area
    @node = node
    @node_tp = interface
    @tp_count = -1
  end

  def to_s
    "ASAreaLink: (#{@tp_count}) #{@as},#{@node},#{@node_tp},#{@area}"
  end

  def sub_area?
    @area.positive?
  end

  def area0_pair?(other)
    @as == other.as && @area.zero? && @node == other.node
  end

  def count_dup
    @tp_count += 1
    return self if @tp_count.zero?

    duplicated = ASAreaLink.new(@as, @area, @node, node_tp_with_count)
    duplicated.tp_count = @tp_count
    duplicated
  end

  # name of ospf-are node in ospf-area layer
  def area_node_name
    "as#{@as}-area#{@area}"
  end

  def area_node_tp_name
    "#{@node}-#{@node_tp}"
  end

  def base_node_tp
    name = @node_tp.split('::')
    if name.length > 1
      name.pop
      name.join('::')
    else
      name[0]
    end
  end

  private

  def node_tp_with_count
    name = @node_tp.split('::')
    if name.length > 1
      name[-1] = @tp_count.to_s
    else
      name.push(@tp_count.to_s)
    end
    name.join('::')
  end
end

# AS-Area links table record
class ASAreaLinkTableRecord < TableRecordBase
  attr_accessor :as, :src, :dst

  def initialize(asn, src, dst)
    @as = asn
    @src = src # ASAreaLink
    @dst = dst # ASAreaLink
  end

  def to_s
    "ASAreaLinkTableRec: #{@as},s=#{@src},d=#{@dst}"
  end

  def check_duplicate
    @dst = @dst.count_dup
  end
end

# AS-Area link table
class ASAreaLinkTable < TableBase
  extend Forwardable

  def_delegators :@records, :each, :find, :[]

  def initialize(target, table_of, debug = false)
    super(target, nil, debug)
    @half_links = table_of[:as_area].make_ospf_area_links
    @records = make_link_table
  end

  def to_s
    @records.map(&:to_s).join("\n").to_s
  end

  private

  def make_link_table
    records = []
    @half_links.filter(&:sub_area?).each do |target_hl|
      dst = @half_links.find { |hl| hl.area0_pair?(target_hl) }
      records.push(ASAreaLinkTableRecord.new(target_hl.as, target_hl, dst))
    end
    records.each(&:check_duplicate)
    records # uni-direction link (sub-area -> area0 (backbone))
  end
end
