# frozen_string_literal: true

require_relative './topo2config_converter_base'
require_relative './tinet_config'

# data converter (layer3 to tinet)
class Topo2Layer3ConfigConverter < Topo2ConfigConverterBase
  def initialize(opts)
    # config option specified in inherited class
    opts[:config] = TinetConfigLayer3.new unless opts.key?(:config) && opts[:config].is_a?(TinetConfigLayer3)
    super(**opts)
    construct_layer3_config
  end

  private

  def construct_layer3_config
    l3_nw = @networks.find_network('layer3')
    @config.add_l3_node_config(l3_nw)
    @config.add_l3_test(l3_nw)
  end
end

# data convert method for ospf (to mix-in)
module OSPFConfigConvertible
  def construct_ospf_config
    ospf_proc_nw = @networks.find_network('ospf-proc')
    @config.add_ospf_node_config(ospf_proc_nw)
    @config.add_ospf_test(ospf_proc_nw)
  end
end

# data converter (ospf)
class Topo2OSPFConfigConverter < Topo2Layer3ConfigConverter
  include OSPFConfigConvertible

  def initialize(opts)
    opts[:config] = TinetConfigOSPF.new
    super(**opts)
    construct_ospf_config
  end
end

# data convert method for bgp (to mix-in)
module BGPConfigConvertible
  def construct_bgp_config
    bgp_as_nw = @networks.find_network('bgp-as')
    bgp_proc_nw = @networks.find_network('bgp-proc')
    @config.add_bgp_node_config(bgp_as_nw, bgp_proc_nw)
    @config.add_bgp_test(bgp_as_nw, bgp_proc_nw)
  end
end

# data converter (bgp)
class Topo2BGPConfigConverter < Topo2Layer3ConfigConverter
  include BGPConfigConvertible

  def initialize(opts)
    opts[:config] = TinetConfigBGP.new
    super(**opts)
    construct_bgp_config
  end
end

# data converter (whole layers)
class Topo2AllConfigConverter < Topo2Layer3ConfigConverter
  include OSPFConfigConvertible
  include BGPConfigConvertible

  def initialize(opts)
    opts[:config] = TinetConfigAll.new
    super(**opts)
    construct_ospf_config
    construct_bgp_config
  end
end
