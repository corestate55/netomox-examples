# frozen_string_literal: true

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

  def node(node_name)
    found_node = find_node_by_name(node_name)
    return found_node if found_node

    new_node = PNode.new(node_name)
    @nodes.push(new_node)
    new_node
  end

  def link(src_node_name, src_tp_name, dst_node_name, dst_tp_name)
    found_link = find_link_by_src_dst_name(src_node_name, src_tp_name, dst_node_name, dst_tp_name)
    return found_link if found_link

    src = PLinkEdge.new(src_node_name, src_tp_name)
    dst = PLinkEdge.new(dst_node_name, dst_tp_name)
    new_link = PLink.new(src, dst)
    @links.push(new_link)
    new_link
  end

  def find_node_by_name(node_name)
    @nodes.find { |node| node.name == node_name }
  end

  def find_link_by_source(node_name, tp_name)
    @links.find do |link|
      link.src.node == node_name && link.src.tp == tp_name
    end
  end

  def find_link_by_src_dst_name(node1, tp1, node2, tp2)
    @links.find do |link|
      link.src.node == node1 && link.src.tp == tp1 &&
        link.dst.node == node2 && link.dst.tp == tp2
    end
  end
end

# pseudo node
class PNode < PObjectBase
  attr_accessor :tps

  def initialize(name)
    super(name)
    @tps = [] # Array of PTermPoint
  end

  def auto_tp_name
    tp_names = @tps.map(&:name).filter { |tp| tp.name =~ /p\d+/ }
    tp_name_numbers = tp_names.map { |tp| tp.name =~ /p(\d+)/; $1.to_i }.sort
    next_number = tp_name_numbers.length > 0 ? tp_name_numbers.pop + 1 : 1
    "p#{next_number}"
  end

  def term_point(tp_name)
    found_tp = find_tp_by_name(tp_name)
    return found_tp if found_tp

    new_tp = PTermPoint.new(tp_name)
    @tps.push(new_tp)
    new_tp
  end

  def find_tp_by_name(tp_name)
    @tps.find { |tp| tp.name == tp_name }
  end

  def to_s
    name.to_s
  end
end

# pseudo termination point
class PTermPoint < PObjectBase
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
