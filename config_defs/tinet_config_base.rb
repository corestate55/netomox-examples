# frozen_string_literal: true

require 'hashie'
require 'yaml'

# Tinet config generator base class
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

  protected

  def format_cmds(cmds)
    cmds.map { |cmd| Hashie::Mash.new(cmd: cmd) }
  end

  def format_vtysh_cmds(cmds)
    vtysh_cmds = ['vtysh']
    vtysh_cmds.concat(cmds.map { |cmd| "-c \"#{cmd}\"" })
    Hashie::Mash.new(cmd: vtysh_cmds.join("\n"))
  end

  def find_node_config_by_name(name)
    @config[:node_configs].find do |config|
      config[:name] == name
    end
  end
end
