# frozen_string_literal: true

require 'json'
require 'netomox'
require 'optparse'

opts = ARGV.getopts('d')
if opts['d']
  puts 'Node Aggregation Check'
  exit 0
end

nws = Netomox::DSL::Networks.new
nws.register do
  vlan_num = 9 # min:1, max:9
  vlan_range = (0..vlan_num)

  network 'layer3' do
    (1..2).each do |i|
      node "switch#{i}-GRT" do
        support %W[layer2 switch#{i}-GRT]
        vlan_range.each do |j|
          term_point "p1#{j}" do
            support %W[layer2 switch#{i}-GRT p1#{j}]
          end
        end
      end
      vlan_range.each do |j|
        node "host#{i}#{j}" do
          support %W[layer2 host#{i}#{j}]
          term_point 'eth0' do
            support %W[layer2 host#{i}#{j} eth0]
          end
        end
      end
    end
    vlan_range.each do |j|
      node "Seg.1#{j}" do
        (1..2).each do |i|
          support %W[layer2 hyp#{i}-vsw1-vlan1#{j}]
          support %W[layer2 switch#{i}-vlan1#{j}]
        end
        term_point 'p1' do
          support %W[layer2 hyp1-vsw1-vlan1#{j} p3]
        end
        term_point 'p2' do
          support %W[layer2 hyp2-vsw1-vlan1#{j} p3]
        end
        term_point 'p3'
        term_point 'p4'
      end

      bdlink %W[host1#{j} eth0 Seg.1#{j} p1]
      bdlink %W[host2#{j} eth0 Seg.1#{j} p2]
      bdlink %W[switch1-GRT p1#{j} Seg.1#{j} p3]
      bdlink %W[switch2-GRT p1#{j} Seg.1#{j} p4]
    end
  end

  network 'layer2' do
    (1..2).each do |i|
      vlan_range.each do |j|
        node "host#{i}#{j}" do
          support %W[layer1.5 host#{i}#{j}]
          term_point 'eth0' do
            support %W[layer1.5 host#{i}#{j} eth0]
          end
        end
        node "hyp#{i}-vsw1-vlan1#{j}" do
          support %W[layer1.5 hyp#{i}-vsw1]
          term_point 'p1' do
            support %W[layer1.5 hyp#{i}-vsw1 p1]
          end
          term_point 'p2' do
            support %W[layer1.5 hyp#{i}-vsw1 p2]
          end
          term_point 'p3'
        end
        node "switch#{i}-vlan1#{j}" do
          support %W[layer1 switch#{i}]
          term_point 'p1' do
            support %W[layer1 switch#{i} p1]
          end
          term_point 'p2' do
            support %W[layer1 switch#{i} p2]
          end
          term_point 'p3' do
            support %W[layer1 switch#{i} p3]
          end
          term_point 'p4'
        end
      end
      node "switch#{i}-GRT" do
        support %W[layer1 switch#{i}]
        vlan_range.each do |j|
          term_point "p1#{j}"
        end
      end
    end
    vlan_range.each do |j|
      bdlink %W[host1#{j} eth0 hyp1-vsw1-vlan1#{j} p3]
      bdlink %W[host2#{j} eth0 hyp2-vsw1-vlan1#{j} p3]
      bdlink %W[hyp1-vsw1-vlan1#{j} p1 switch1-vlan1#{j} p1]
      bdlink %W[hyp1-vsw1-vlan1#{j} p2 switch2-vlan1#{j} p1]
      bdlink %W[hyp2-vsw1-vlan1#{j} p1 switch1-vlan1#{j} p2]
      bdlink %W[hyp2-vsw1-vlan1#{j} p2 switch2-vlan1#{j} p2]
      bdlink %W[switch1-vlan1#{j} p3 switch2-vlan1#{j} p3]
      bdlink %W[switch1-vlan1#{j} p4 switch1-GRT p1#{j}]
      bdlink %W[switch2-vlan1#{j} p4 switch2-GRT p1#{j}]
    end
  end

  network 'layer1.5' do
    (1..2).each do |i|
      vlan_range.each do |j|
        node "host#{i}#{j}" do
          support %W[layer1 hyp#{i}]
          term_point 'eth0'
        end
      end
      node "hyp#{i}-vsw1" do
        support %W[layer1 hyp#{i}]
        term_point 'p1' do
          support %W[layer1 hyp#{i} p1]
        end
        term_point 'p2' do
          support %W[layer1 hyp#{i} p2]
        end
        vlan_range.each do |j|
          term_point "p1#{j}"
        end
      end
      vlan_range.each do |j|
        bdlink %W[hyp#{i}-vsw1 p1#{j} host#{i}#{j} eth0]
      end
    end
  end

  network 'layer1' do
    (1..2).each do |i|
      node "hyp#{i}" do
        term_point 'p1'
        term_point 'p2'
      end
      node "switch#{i}" do
        term_point 'p1'
        term_point 'p2'
        term_point 'p3'
      end
    end
    bdlink %w[hyp1 p1 switch1 p1]
    bdlink %w[hyp1 p2 switch2 p1]
    bdlink %w[hyp2 p1 switch1 p2]
    bdlink %w[hyp2 p2 switch2 p2]
    bdlink %w[switch1 p3 switch2 p3]
  end
end

puts JSON.pretty_generate(nws.topo_data)
