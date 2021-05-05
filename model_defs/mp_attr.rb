# frozen_string_literal: true

require 'json'
require 'netomox'
require 'optparse'

opts = ARGV.getopts('d')
if opts['d']
  puts 'Multi-purpose attribute trial'
  exit 0
end

nws = Netomox::DSL::Networks.new
nws.register do
  network 'monitor-region' do
    type Netomox::NWTYPE_OPS

    support 'system-monitor'

    node 'region1' do
      attribute(
        region_id: 'r100001',
        place: 'Nishi-shinjuku'
      )
      support %w[system-monitor network1]
      support %w[system-monitor sv1]
      support %w[system-monitor sv2]
    end
  end

  network 'system-monitor' do
    type Netomox::NWTYPE_OPS

    attribute(
      description: 'relation of monitoring objects',
      network: '192.168.1.0/24'
    )

    node 'network1' do
      attribute(
        name: 'server-segment',
        monitor_id: 20_001
      )
      term_point 'sv1'
      term_point 'sv2'
    end
    node 'sv1' do
      attribute(
        name: 'server1',
        monitor_id: 30_001
      )
      term_point 'eth0' do
        attribute(address: '192.168.1.101')
      end
    end
    node 'sv2' do
      attribute(
        name: 'server2',
        monitor_id: 30_002
      )
      term_point 'eth0' do
        attribute(address: '192.168.1.102')
      end
    end

    bdlink %w[network1 sv1 sv1 eth0]
    bdlink %w[network1 sv2 sv2 eth0]
  end
end

puts JSON.pretty_generate(nws.topo_data)
