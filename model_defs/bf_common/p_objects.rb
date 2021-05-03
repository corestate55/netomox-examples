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
