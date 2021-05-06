# frozen_string_literal: true

require_relative './tinet_config_base'
require_relative './tinet_config_layer3'
require_relative './tinet_config_ospf'
require_relative './tinet_config_bgp'

# Tinet config generator for layer3 topology model
class TinetConfigLayer3 < TinetConfigBase
  include TinetConfigLayer3Module
end

# Tinet config generator for ospf-proc topology model
class TinetConfigOSPF < TinetConfigLayer3
  include TinetConfigOSPFModule
end

# Tinet config generator for bgp-proc topology model
class TinetConfigBGP < TinetConfigLayer3
  include TinetConfigBGPModule
end

# whole layers
class TinetConfigAll < TinetConfigLayer3
  include TinetConfigOSPFModule
  include TinetConfigBGPModule
end
