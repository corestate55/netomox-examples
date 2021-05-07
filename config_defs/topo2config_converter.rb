# frozen_string_literal: true

require_relative './topo2config_converter_base'
require_relative './tinet_config_all'

# data converter (layer3 to tinet)
class Topo2Layer3ConfigConverter < Topo2ConfigConverterBase
  def initialize(opts)
    super(opts)
    construct_layer3_config
  end

  private

  def construct_layer3_config
    l3_nw = @networks.find_network('layer3')
    l3_nw.nodes.each do |node|
      @tinet_config.add_l3_node(l3_nw, node)
      @tinet_config.add_l3_node_config(node)
    end
    @tinet_config.add_l3_test_by_nw(l3_nw)
  end
end

# data convert method for ospf (to mix-in)
module Topo2OSPFConfigConverterModule
  def construct_ospf_config
    ospf_proc_nw = @networks.find_network('ospf-proc')
    ospf_proc_nw.nodes.each do |node|
      @tinet_config.add_ospf_node_config(node)
      @tinet_config.add_ospf_test(node)
    end
  end
end

# data converter (ospf)
class Topo2OSPFConfigConverter < Topo2Layer3ConfigConverter
  include Topo2OSPFConfigConverterModule

  def initialize(opts)
    super(opts)
    construct_ospf_config
  end
end

# data convert method for bgp (to mix-in)
module Topo2BGPConfigConverterModule
  def construct_bgp_config
    bgp_as_nw = @networks.find_network('bgp-as')
    bgp_proc_nw = @networks.find_network('bgp-proc')
    @tinet_config.add_bgp_node_config_by_nw(bgp_as_nw, bgp_proc_nw)
    @tinet_config.add_bgp_test_by_nw(bgp_as_nw, bgp_proc_nw)
  end
end

# data converter (bgp)
class Topo2BGPConfigConverter < Topo2Layer3ConfigConverter
  include Topo2BGPConfigConverterModule

  def initialize(opts)
    super(opts)
    construct_bgp_config
  end
end

# data converter (whole layers)
class Topo2AllConfigConverter < Topo2Layer3ConfigConverter
  include Topo2OSPFConfigConverterModule
  include Topo2BGPConfigConverterModule

  def initialize(opts)
    super(opts)
    construct_ospf_config
    construct_bgp_config
  end
end
