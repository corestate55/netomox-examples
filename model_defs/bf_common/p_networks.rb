# frozen_string_literal: true

require 'netomox'
require_relative 'p_objects'

# pseudo networks: Netomox-DSL interpreter
class PNetworks
  extend Forwardable

  def_delegators :@networks, :each, :find, :push, :[]
  attr_accessor :networks, :nmx_networks

  def initialize
    @networks = []
    @nmx_networks = Netomox::DSL::Networks.new
  end

  def dump
    @networks.each(&:dump)
  end

  def interpret
    @networks.each { |network| interpret_network(network) }
    @nmx_networks
  end

  private

  def make_nmx_network(network)
    nmx_network = @nmx_networks.network(network.name)
    nmx_network.attribute(network.attribute) if network.attribute
    nmx_network.type(network.type) if network.type
    nmx_network
  end

  def interpret_network(network)
    nmx_network = make_nmx_network(network)
    network.supports.each { |s| nmx_network.support(s) }
    network.nodes.each { |node| interpret_node(node, nmx_network) }
    network.links.each { |link| interpret_link(link, nmx_network) }
  end

  def interpret_tp(term_point, nmx_node)
    nmx_tp = nmx_node.tp(term_point.name)
    nmx_tp.attribute(term_point.attribute) if term_point.attribute
    term_point.supports.each { |s| nmx_tp.support(s) }
  end

  def interpret_node(node, nmx_network)
    nmx_node = nmx_network.node(node.name)
    nmx_node.attribute(node.attribute) if node.attribute
    node.supports.each { |s| nmx_node.support(s) }
    node.tps.each { |tp| interpret_tp(tp, nmx_node) }
  end

  def interpret_link(link, nmx_network)
    nmx_network.link(link.src.node, link.src.tp, link.dst.node, link.dst.tp)
  end
end
