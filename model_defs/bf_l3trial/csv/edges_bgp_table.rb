# frozen_string_literal: true

require 'forwardable'
require_relative 'table_base'
require_relative 'edges_bgp_utils'

# row of edges-bgp table
class EdgesBGPTableRecord < TableRecordBase
  attr_accessor :src, :dst

  def initialize(record, table_of, debug = false)
    super(debug)

    @ip_owners_table = table_of[:ip_owners]
    @src = new_bgp_edge(%i[node ip as_number], record, table_of)
    @dst = new_bgp_edge(%i[remote_node remote_ip remote_as_number],
                        record, table_of)
  end

  def make_as_link
    LinksInterASTableRecord.new(@src, @dst)
  end

  def proc_link_tp(link_ref_count, tp_ref_count)
    fwd_key, rev_key = proc_link_key_pair
    debug "###### fwd_key=#{fwd_key}, rev_key=#{rev_key}"

    if link_ref_count[fwd_key].nil? && link_ref_count[rev_key].nil?
      # there are no forward/reverse link of src/dst,
      # count tp_ref and put forward link.
      count_forward_link(fwd_key, link_ref_count, tp_ref_count)
    elsif link_ref_count[fwd_key].nil?
      # exist reverse link of src/dst. put reverse link.
      count_reverse_link(fwd_key, rev_key, link_ref_count)
    else
      warn 'WARNING: duplicated link?'
    end

    make_proc_link(link_ref_count, fwd_key)
  end

  private

  def make_proc_link(link_ref_count, fwd_key)
    @src.save_counted_ip(link_ref_count[fwd_key][0])
    @dst.save_counted_ip(link_ref_count[fwd_key][1])
    debug "### src: #{@src.node}, #{@src.ip}, #{@src.interface}"
    debug "### dst: #{@dst.node}, #{@dst.ip}, #{@dst.interface}"

    self # return this @src and @dst pair
  end

  def count_forward_link(fwd_key, link_ref_count, tp_ref_count)
    tp_ref_count.count_of(@src)
    tp_ref_count.count_of(@dst)
    link_ref_count.count_of(fwd_key, tp_ref_count[@src], tp_ref_count[@dst])
    debug "### rev/fwd not found, #{link_ref_count[fwd_key]}"
  end

  def count_reverse_link(fwd_key, rev_key, link_ref_count)
    link_ref_count.count_of(fwd_key, *link_ref_count[rev_key].reverse)
    debug "### rev found (fwd not found), #{link_ref_count[fwd_key]}"
  end

  def new_bgp_edge(keys, record, table_of)
    opts = edge_opts(keys, record, table_of)
    BGPEdge.new(*opts)
  end

  def edge_opts(keys, record, table_of)
    node = record[keys[0]] # 0 => :node or :remote_node
    ip = record[keys[1]] # 1 => :ip or :remote_ip
    additions = [
      table_of[:config_bgp_proc].find_router_id(node),
      table_of[:ip_owners].find_interface(node, ip)
    ]
    keys.map { |k| record[k] }.push(*additions)
  end

  def proc_link_key_pair
    # forward, reverse
    [proc_link_key(@src, @dst), proc_link_key(@dst, @src)]
  end

  def proc_link_key(src, dst)
    "#{src.key}-#{dst.key}"
  end
end

# edges-bgp tableX
class EdgesBGPTable < TableBase
  extend Forwardable

  def_delegators :@records, :each, :find, :[]

  def initialize(target, table_of, debug = false)
    super(target, 'edges_bgp.csv', debug)

    @records = @orig_table.map do |rec|
      EdgesBGPTableRecord.new(rec, table_of, debug)
    end
  end

  def as_numbers
    @orig_table[:as_number].uniq
  end

  def find_edges(node, neighbor_ip)
    @records.find do |rec|
      rec.src.node == node && rec.dst.ip == neighbor_ip.gsub(%r{/\d+}, '')
    end
  end

  def find_all_by_as(asn)
    @records.find_all { |r| r.src.as_number == asn }
  end

  def nodes_in(asn)
    @records
      .find_all { |row| row.src.as_number == asn }
      .map { |row| row.src.node }
      .sort.uniq
  end

  # make links_inter_as_table (LinksInterASTable)
  def make_links_inter_as
    @records
      .find_all { |r| r.src.as_number != r.dst.as_number }
      .map(&:make_as_link)
  end

  def make_proc_links
    link_ref_count = ProcLinkRefCounter.new
    tp_ref_count = ProcTpRefCounter.new
    proc_links = []
    @records.each do |rec|
      proc_links.push(rec.proc_link_tp(link_ref_count, tp_ref_count))
    end
    proc_links
  end
end
