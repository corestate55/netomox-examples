# frozen_string_literal: true

require 'json'
require 'yaml'
require 'netomox'

# base class of tinet config converter
class Topo2ConfigConverterBase
  def initialize(opts)
    @file = opts[:file]
    @tinet_config = opts[:tinet_config]
    @debug = opts[:debug]
    warn "file: #{@file}, tinet_config:#{@tinet_config.class}" if @debug

    @topology_data = read_topology_data
    @networks = convert_data_to_topology
    convert_interface_name
  end

  def to_s
    "nws: #{@networks.networks.map(&:name)}"
  end

  def to_config
    @tinet_config.to_yaml
  end

  private

  # does specified interface name satisfies linux veth interface name constraints?
  def invalid_ifname?(name)
    !name.ascii_only? || name.include?(' ') || name.length > 15
  end

  # check and convert interface name
  def check_interface_name(name)
    warn "Interface name is invalid or too log: #{name}" if invalid_ifname?(name)
    name.tr!(' ', '_')
    name.tr!('/', '-')
    name
  end

  def convert_ifname_for_term_points
    @networks.all_termination_points do |tp, _node, _nw|
      # Notice: patched to rewrite tp name
      tp.name = check_interface_name(tp.name)
      tp.supports.each { |stp| stp.tp_ref = check_interface_name(stp.tp_ref) }
    end
  end

  def convert_ifname_for_links
    @networks.all_links do |link, _nw|
      link.source.tp_ref = check_interface_name(link.source.tp_ref)
      link.destination.tp_ref = check_interface_name(link.destination.tp_ref)
    end
  end

  def convert_interface_name
    convert_ifname_for_term_points
    convert_ifname_for_links
  end

  def convert_data_to_topology
    Netomox::Topology::Networks.new(@topology_data)
  end

  def read_topology_data(opt_hash = {})
    JSON.parse(File.read(@file), opt_hash)
  rescue StandardError => e
    warn e
    exit 1
  end
end
