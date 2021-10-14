# frozen_string_literal: true

require 'netomox'

# rubocop:disable Metrics/MethodLength, Metrics/AbcSize
def register_target_ospf_proc(nws)
  nws.register do
    network 'ospf_proc' do
      support 'layer3'

      # RegionA Nodes
      node 'RegionA-PE01' do
        support %w[layer3 RegionA-PE01-GRT]
        (2..3).each do |i|
          term_point "p#{i}" do
            support %W[layer3 RegionA-PE01-GRT p#{i}]
          end
        end
      end
      node 'RegionA-PE02' do
        support %w[layer3 RegionA-PE02-GRT]
        (2..3).each do |i|
          term_point "p#{i}" do
            support %W[layer3 RegionA-PE02-GRT p#{i}]
          end
        end
      end

      node 'RegionA-CE01' do
        support %w[layer3 RegionA-CE01-GRT]
        (2..3).each do |i|
          term_point "p#{i}" do
            support %W[layer3 RegionA-CE01-GRT p#{i}]
          end
        end
      end
      node 'RegionA-CE02' do
        support %w[layer3 RegionA-CE02-GRT]
        (2..3).each do |i|
          term_point "p#{i}" do
            support %W[layer3 RegionA-CE02-GRT p#{i}]
          end
        end
      end

      # RegionA Links
      bdlink %w[RegionA-PE01 p2 RegionA-CE01 p2]
      bdlink %w[RegionA-PE01 p3 RegionA-CE02 p2]
      bdlink %w[RegionA-PE02 p2 RegionA-CE01 p3]
      bdlink %w[RegionA-PE02 p3 RegionA-CE02 p3]

      # RegionB Nodes
      node 'RegionB-PE01' do
        support %w[layer3 RegionB-PE01-GRT]
        (2..3).each do |i|
          term_point "p#{i}" do
            support %W[layer3 RegionB-PE01-GRT p#{i}]
          end
        end
      end
      node 'RegionB-PE02' do
        support %w[layer3 RegionB-PE02-GRT]
        (2..3).each do |i|
          term_point "p#{i}" do
            support %W[layer3 RegionB-PE02-GRT p#{i}]
          end
        end
      end

      node 'RegionB-CE01' do
        support %w[layer3 RegionB-CE01-GRT]
        (2..3).each do |i|
          term_point "p#{i}" do
            support %W[layer3 RegionB-CE01-GRT p#{i}]
          end
        end
      end
      node 'RegionB-CE02' do
        support %w[layer3 RegionB-CE02-GRT]
        (2..3).each do |i|
          term_point "p#{i}" do
            support %W[layer3 RegionB-CE02-GRT p#{i}]
          end
        end
      end

      # RegionB Links
      bdlink %w[RegionB-PE01 p2 RegionB-CE01 p2]
      bdlink %w[RegionB-PE01 p3 RegionB-CE02 p2]
      bdlink %w[RegionB-PE02 p2 RegionB-CE01 p3]
      bdlink %w[RegionB-PE02 p3 RegionB-CE02 p3]
    end
  end
end
# rubocop:enable Metrics/MethodLength, Metrics/AbcSize
