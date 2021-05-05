# frozen_string_literal: true

# Mix-in module to construct bgp tinet config
module TinetConfigBGPModule
  # sectioned command list
  class SectionCommandList
    def initialize
      # initial: empty command list
      @section = {
        conf_t: [],
        bgp_header: '', # single command string
        bgp_common: [],
        bgp_ipv4uc: []
      }
    end

    # @param [Array<String>] commands
    def push(section, commands)
      @section[section].push(*commands)
    end

    # @param [String] command
    def store_bgp_header(command)
      # bgp-header is special use commands to enter bgp configuration
      @section[:bgp_header] = command
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

    def bgp_header
      @section[:bgp_header]
    end

    def bgp_common
      @section[:bgp_common]
    end

    def bgp_ipv4uc
      @section[:bgp_ipv4uc]
    end

    def uniq_all!
      @section.each_key
              .filter { |key| @section[key].kind_of?(Array) }
              .each { |key| @section[key].uniq! }
    end

    # @param [SectionCommandList] cmd_list
    def append_section(cmd_list)
      push_conf_t(cmd_list.conf_t)
      # not modified bgp-header: it is constant
      push_bgp_common(cmd_list.bgp_common)
      push_bgp_ipv4uc(cmd_list.bgp_ipv4uc)
    end

    # @return [Array<String>]
    def list_all_commands
      [
        'conf t',
        @section[:conf_t],
        @section[:bgp_header],
        @section[:bgp_common],
        'address-family ipv4 unicast',
        @section[:bgp_ipv4uc],
        'exit-address-family',
        'exit', # router bgp
        'exit' # conf t
      ].flatten
    end
  end
end
