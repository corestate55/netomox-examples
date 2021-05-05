# frozen_string_literal: true

require 'forwardable'
require_relative 'table_base'

# row of config-bgp-peer table
class ConfigBGPPeerTableRecord < TableRecordBase
  attr_accessor :node, :local_as, :local_ip, :confederation, :remote_as, :remote_ip, :rr_client, :cluster_id

  def initialize(record, debug = false)
    super(debug)

    @node = record[:node]
    @local_as = record[:local_as]
    @local_ip = record[:local_ip]
    @confederation = record[:confederation]
    @remote_as = record[:remote_as]
    @remote_ip = record[:remote_ip]
    @rr_client = record[:route_reflector_client] # True/False
    @cluster_id = record[:cluster_id]
  end

  def rr_server?
    @rr_client == 'True' # means the record is RR-Server -> RR-Client info
  end

  def to_s
    'ConfigBGPPeerTableRec: ' \
      "#{@node},#{@local_as},#{@local_ip},#{@confederation},#{@remote_as},#{@remote_ip},#{@rr_client},#{@cluster_id}"
  end
end

# config-bgp-peer table
class ConfigBGPPeerTable < TableBase
  extend Forwardable

  def_delegators :@records, :each, :find, :[]

  def initialize(target, debug = false)
    super(target, 'config_bgp_peer.csv', debug)

    @records = @orig_table.map do |rec|
      ConfigBGPPeerTableRecord.new(rec, debug)
    end
    @rr_peers = make_rr_peers
  end

  def local_asn(node)
    find_rec_by_node(node)&.local_as
  end

  def confederation_asn(node)
    find_rec_by_node(node)&.confederation
  end

  def rr_data(node)
    # search as RR server
    found = find_node_as_rr_server(node)
    return found if found

    # search as RR client
    found = find_node_as_rr_client(node)
    return found if found

    # no RR proc
    {}
  end

  def to_s
    @records.map(&:to_s).join("\n").to_s
  end

  private

  def find_node_as_rr_server(node)
    found_servers = @rr_peers.find_all { |peer| peer[:node] == node }
    return nil if found_servers.empty?

    rr_clients = found_servers.map { |peer| peer[:client_peer] }
    { type: :server, cluster_id: found_servers[0][:cluster_id], clients: rr_clients }
  end

  def find_node_as_rr_client(node)
    node_recs = find_all_recs_by_node(node)
    return nil if node_recs.empty?

    node_local_ips = node_recs.map(&:local_ip)
    # A RR-client is able to have multiple servers
    server_recs = find_all_rr_server_recs.find_all { |rec| node_local_ips.include?(rec.remote_ip) }
    return nil if server_recs.empty?

    servers = server_recs.map(&:local_ip)
    { type: :client, servers: servers }
  end

  def make_rr_peers
    rr_server_recs = find_all_rr_server_recs
    rr_server_recs.map do |rec|
      {
        node: rec.node,
        cluster_id: rec.cluster_id,
        client_asn: rec.remote_as,
        client_peer: rec.remote_ip
      }
    end
  end

  def find_all_rr_server_recs
    @records.find_all(&:rr_server?)
  end

  def find_rec_by_node(node)
    @records.find { |rec| rec.node == node }
  end

  def find_all_recs_by_node(node)
    @records.find_all { |rec| rec.node == node }
  end
end
