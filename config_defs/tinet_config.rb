# frozen_string_literal: true

require 'hashie'
require 'yaml'

require_relative './frr_layer3_configurable'
require_relative './frr_ospf_configurable'
require_relative './frr_bgp_configurable'

# Base class of tinet config wrapper.
class TinetConfigBase
  attr_reader :config

  def initialize
    @config = Hashie::Mash.new(
      nodes: [],
      node_configs: [],
      test: { cmds: [] }
    )
  end

  def to_yaml
    # change multiple line string format of commands:
    # blick/chomp(|-) to fold/chomp(>-)
    YAML.dump(@config.to_hash).tr('cmd: |-', 'cmd: >-')
  end
end

# Tinet config generator for layer3 topology model
class TinetConfigLayer3 < TinetConfigBase
  include FrrLayer3Configurable
end

# Tinet config generator for ospf-proc topology model
class TinetConfigOSPF < TinetConfigLayer3
  include FrrOSPFConfigurable
end

# Tinet config generator for bgp-proc topology model
class TinetConfigBGP < TinetConfigLayer3
  include FrrBGPConfigurable
end

# whole layers
class TinetConfigAll < TinetConfigLayer3
  include FrrOSPFConfigurable
  include FrrBGPConfigurable
end
