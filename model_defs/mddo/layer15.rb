# frozen_string_literal: true

require 'netomox'

# rubocop:disable Metrics/MethodLength, Metrics/AbcSize
def register_target_layer15(nws)
  nws.register do
    network 'layer15' do
      support 'layer1'

      # RegionA Nodes
      node 'RegionA-CE01' do
        support %w[layer1 RegionA-CE01]
        term_point 'p01' do
          (0..1).each { |i| support %W[layer1 RegionA-CE01 p#{i}] }
        end
        term_point 'p45' do
          (4..5).each { |i| support %W[layer1 RegionA-CE01 p#{i}] }
        end
      end
      node 'RegionA-CE02' do
        support %w[layer1 RegionA-CE02]
        term_point 'p01' do
          (0..1).each { |i| support %W[layer1 RegionA-CE02 p#{i}] }
        end
        term_point 'p45' do
          (4..5).each { |i| support %W[layer1 RegionA-CE02 p#{i}] }
        end
      end

      node 'RegionA-Acc01' do
        support %w[layer1 RegionA-Acc01]
        term_point 'p01' do
          (0..1).each { |i| support %W[layer1 RegionA-Acc01 p#{i}] }
        end
        term_point 'p23' do
          (2..3).each { |i| support %W[layer1 RegionA-Acc01 p#{i}] }
        end
      end

      # RegionA Links
      bdlink %w[RegionA-CE01 p01 RegionA-CE02 p01]
      bdlink %w[RegionA-CE01 p45 RegionA-Acc01 p01]
      bdlink %w[RegionA-CE02 p45 RegionA-Acc01 p23]

      # RegionB Nodes
      node 'RegionB-CE01' do
        support %w[layer1 RegionB-CE01]
        term_point 'p01' do
          (0..1).each { |i| support %W[layer1 RegionB-CE01 p#{i}] }
        end
        term_point 'p45' do
          (4..5).each { |i| support %W[layer1 RegionB-CE01 p#{i}] }
        end
        term_point 'p67' do
          (6..7).each { |i| support %W[layer1 RegionB-CE01 p#{i}] }
        end
      end
      node 'RegionB-CE02' do
        support %w[layer1 RegionB-CE02]
        term_point 'p01' do
          (0..1).each { |i| support %W[layer1 RegionB-CE02 p#{i}] }
        end
        term_point 'p45' do
          (4..5).each { |i| support %W[layer1 RegionB-CE02 p#{i}] }
        end
        term_point 'p67' do
          (6..7).each { |i| support %W[layer1 RegionB-CE02 p#{i}] }
        end
      end

      node 'RegionB-Acc01' do
        support %w[layer1 RegionB-Acc01]
        term_point 'p01' do
          (0..1).each { |i| support %W[layer1 RegionB-Acc01 p#{i}] }
        end
        term_point 'p23' do
          (2..3).each { |i| support %W[layer1 RegionB-Acc01 p#{i}] }
        end
      end
      node 'RegionB-Acc02' do
        support %w[layer1 RegionB-Acc02]
        term_point 'p01' do
          (0..1).each { |i| support %W[layer1 RegionB-Acc02 p#{i}] }
        end
        term_point 'p23' do
          (2..3).each { |i| support %W[layer1 RegionB-Acc02 p#{i}] }
        end
      end

      # RegionB Links
      bdlink %w[RegionB-CE01 p01 RegionB-CE02 p01]
      bdlink %w[RegionB-CE01 p45 RegionB-Acc01 p01]
      bdlink %w[RegionB-CE02 p45 RegionB-Acc01 p23]
    end
  end
end
# rubocop:enable Metrics/MethodLength, Metrics/AbcSize
