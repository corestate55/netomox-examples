# frozen_string_literal: true

require 'netomox'

# rubocop:disable Metrics/MethodLength, Metrics/AbcSize
def register_target_bgp_proc(nws)
  nws.register do
    network 'bgp-proc' do
      support 'layer3'

      # RegionA Nodes
      node 'RegionA-PE01' do
        (0..1).each do |i|
          term_point "p#{i}" do
            support %W[layer3 RegionA-PE01-GRT p#{i}]
          end
        end
        support %w[layer3 RegionA-PE01-GRT]
      end

      node 'RegionA-PE02' do
        (0..1).each do |i|
          term_point "p#{i}" do
            support %W[layer3 RegionA-PE02-GRT p#{i}]
          end
        end
        support %w[layer3 RegionA-PE02-GRT]
      end

      # RegionB Nodes
      node 'RegionB-PE01' do
        (0..1).each do |i|
          term_point "p#{i}" do
            support %W[layer3 RegionB-PE01-GRT p#{i}]
          end
        end
        support %w[layer3 RegionB-PE01-GRT]
      end

      node 'RegionB-PE02' do
        (0..1).each do |i|
          term_point "p#{i}" do
            support %W[layer3 RegionB-PE02-GRT p#{i}]
          end
        end
        support %w[layer3 RegionB-PE02-GRT]
      end

      # Links
      bdlink %w[RegionA-PE01 p0 RegionA-PE02 p0]
      bdlink %w[RegionB-PE01 p0 RegionB-PE02 p0]

      bdlink %w[RegionA-PE01 p1 RegionB-PE01 p1]
      bdlink %w[RegionA-PE02 p1 RegionB-PE02 p1]
    end
  end
end
# rubocop:enable Metrics/MethodLength, Metrics/AbcSize
