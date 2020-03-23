# frozen_string_literal: true

require 'forwardable'
require 'netomox'

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

# base class for pseudo network object
class PObjectBase
  attr_accessor :name, :attribute, :supports

  def initialize(name)
    @name = name
    @attribute = nil
    @supports = []
  end
end

# pseudo network
class PNetwork < PObjectBase
  attr_accessor :nodes, :links, :type

  def initialize(name)
    super(name)
    @type = nil
    @nodes = []
    @links = []
  end

  def dump
    warn "network: #{name}"
    warn '  nodes:'
    @nodes.each { |n| warn "    - #{n}" }
    warn '  links:'
    @links.each { |l| warn "    - #{l}" }
  end
end

# pseudo node
class PNode < PObjectBase
  attr_accessor :tps

  def initialize(name)
    super(name)
    @tps = [] # Array of PTermPoint
  end

  def to_s
    name.to_s
  end
end

# pseudo termination point
class PTermPoint < PObjectBase
  def initialize(name)
    super(name)
  end

  def to_s
    "[#{name}]"
  end
end

# base class for pseudo link
class PLinkEdge
  attr_accessor :node, :tp

  def initialize(node, term_point)
    @node = node
    @tp = term_point
  end

  def to_s
    "#{node}[#{tp}]"
  end
end

# pseudo link
class PLink
  attr_accessor :src, :dst

  # src, dst: PLinkEdge
  def initialize(src, dst)
    @src = src
    @dst = dst
  end

  def to_s
    "#{src} > #{dst}"
  end
end

# base class for data builder with pseudo networks
class DataBuilderBase
  attr_accessor :networks

  def initialize
    @networks = PNetworks.new # PNetworks
    @nodes = [] # Array of PNodes
    @links = [] # Array of PLinks
  end

  def interpret
    @networks.interpret
  end

  def topo_data
    interpret.topo_data
  end

  def dump
    @networks.dump
  end

  protected

  def find_node(node_name)
    @nodes.find { |n| n.name == node_name }
  end

  def find_or_new_node(node_name)
    find_node(node_name) || PNode.new(node_name)
  end

  def add_link(src_node, src_tp, dst_node, dst_tp, bidirectional = true)
    src = PLinkEdge.new(src_node, src_tp)
    dst = PLinkEdge.new(dst_node, dst_tp)
    @links.push(PLink.new(src, dst))
    @links.push(PLink.new(dst, src)) if bidirectional
  end

  def add_node_if_new(pnode)
    return if find_node(pnode.name)

    @nodes.push(pnode)
  end
end
