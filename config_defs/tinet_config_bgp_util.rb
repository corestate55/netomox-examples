# frozen_string_literal: true

# Mix-in module to construct bgp tinet config
module TinetConfigBGPModule
  # sectioned command list
  class SectionCommandList
    def initialize
      # initial: empty command list
      @section = { conf_t: [], bgp_common: [], bgp_ipv4uc: [] }
    end

    # commands: Array
    def push(section, commands)
      @section[section].push(*commands)
    end

    def push_conf_t(commands)
      push(:conf_t, commands)
    end

    def push_bgp_common(commands)
      push(:bgp_common, commands)
    end

    def push_bgp_ipv4uc(commands)
      push(:bgp_ipv4uc, commands)
    end

    def conf_t
      @section[:conf_t]
    end

    def bgp_common
      @section[:bgp_common]
    end

    def bgp_ipv4uc
      @section[:bgp_ipv4uc]
    end

    def uniq_all!
      @section.each_key { |key| @section[key].uniq! }
    end

    def append_section(cmd_list)
      push_conf_t(cmd_list.conf_t)
      push_bgp_common(cmd_list.bgp_common)
      push_bgp_ipv4uc(cmd_list.bgp_ipv4uc)
    end

    def list_all_commands
      [
        'conf t',
        @section[:conf_t],
        @section[:bgp_common],
        'address-family ipv4 unicast',
        @section[:bgp_ipv4uc],
        'exit-address-family',
        'exit', # router bgp
        'exit' # conf t
      ].flatten!
    end
  end
end
