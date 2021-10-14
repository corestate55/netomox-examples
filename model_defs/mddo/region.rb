# frozen_string_literal: true

require 'netomox'

def register_target_region(nws)
  nws.register do
    network 'region' do
      support 'bgp-proc'
      support 'ospf-proc'

      node 'RegionA' do
        %w[PE01 PE02].each do |node_name|
          support %W[bgp-proc RegionA-#{node_name}]
        end
        %w[PE01 PE02 CE01 CE02].each do |node_name|
          support %W[ospf-proc RegionA-#{node_name}]
        end
        %w[CE01-VRF CE02-VRF VL10 VL20 VL110 VL120 Svr01 Svr02].each do |node_name|
          support %W[layer3 RegionA-#{node_name}]
        end
        term_point 'p0' do
          support %w[bgp-proc RegionA-PE01 p0]
        end
        term_point 'p1' do
          support %w[bgp-proc RegionA-PE02 p0]
        end
      end

      node 'RegionB' do
        %w[PE01 PE02].each do |node_name|
          support %W[bgp-proc RegionB-#{node_name}]
        end
        %w[PE01 PE02 CE01 CE02].each do |node_name|
          support %W[ospf-proc RegionB-#{node_name}]
        end
        %w[CE01-VRF CE02-VRF VL10 VL20 VL110 VL120 Svr01 Svr02].each do |node_name|
          support %W[layer3 RegionB-#{node_name}]
        end
        term_point 'p0' do
          support %w[bgp-proc RegionB-PE01 p0]
        end
        term_point 'p1' do
          support %w[bgp-proc RegionB-PE02 p0]
        end
      end

      bdlink %w[RegionA p0 RegionB p0]
      bdlink %w[RegionA p1 RegionB p1]
    end
  end
end
