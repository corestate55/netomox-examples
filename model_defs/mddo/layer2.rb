# frozen_string_literal: true

require 'netomox'

# rubocop:disable Metrics/MethodLength, Metrics/AbcSize
def register_target_layer2(nws)
  nws.register do
    network 'layer2' do
      support 'layer1'

      # RegionA Nodes
      node 'RegionA-CE01-GRT' do
        (0..1).each { |i| term_point "p#{i}" }
        support %w[layer15 RegionA-CE01]
      end
      node 'RegionA-CE01-VRF' do
        (0..1).each { |i| term_point "p#{i}" }
        support %w[layer15 RegionA-CE01]
      end

      node 'RegionA-CE02-GRT' do
        (0..1).each { |i| term_point "p#{i}" }
        support %w[layer15 RegionA-CE02]
      end
      node 'RegionA-CE02-VRF' do
        (0..1).each { |i| term_point "p#{i}" }
        support %w[layer15 RegionA-CE02]
      end

      node 'RegionA-CE01-VL10' do
        term_point 'p0'
        term_point 'p1' do
          support %w[layer15 RegionA-CE01 p45]
        end
        term_point 'p2' do
          support %w[layer15 RegionA-CE01 p01]
        end
        support %w[layer15 RegionA-CE01]
      end
      node 'RegionA-CE01-VL20' do
        term_point 'p0'
        term_point 'p1' do
          support %w[layer15 RegionA-CE01 p01]
        end
        support %w[layer15 RegionA-CE01]
      end
      node 'RegionA-CE01-VL110' do
        term_point 'p0'
        term_point 'p1' do
          support %w[layer15 RegionA-CE01 p45]
        end
        term_point 'p2' do
          support %w[layer15 RegionA-CE01 p01]
        end
        support %w[layer15 RegionA-CE01]
      end
      node 'RegionA-CE01-VL120' do
        term_point 'p0'
        term_point 'p1' do
          support %w[layer15 RegionA-CE01 p01]
        end
        support %w[layer15 RegionA-CE01]
      end

      node 'RegionA-CE02-VL10' do
        term_point 'p0'
        term_point 'p1' do
          support %w[layer15 RegionA-CE02 p45]
        end
        term_point 'p2' do
          support %w[layer15 RegionA-CE02 p01]
        end
        support %w[layer15 RegionA-CE02]
      end
      node 'RegionA-CE02-VL20' do
        term_point 'p0'
        term_point 'p1' do
          support %w[layer15 RegionA-CE02 p01]
        end
        support %w[layer15 RegionA-CE02]
      end
      node 'RegionA-CE02-VL110' do
        term_point 'p0'
        term_point 'p1' do
          support %w[layer15 RegionA-CE02 p45]
        end
        term_point 'p2' do
          support %w[layer15 RegionA-CE02 p01]
        end
        support %w[layer15 RegionA-CE02]
      end
      node 'RegionA-CE02-VL120' do
        term_point 'p0'
        term_point 'p1' do
          support %w[layer15 RegionA-CE02 p01]
        end
        support %w[layer15 RegionA-CE02]
      end

      node 'RegionA-Acc01-VL10' do
        term_point 'p0' do
          support %w[layer15 RegionA-Acc01 p01]
        end
        term_point 'p1' do
          support %w[layer15 RegionA-Acc01 p23]
        end
        term_point 'p2' do
          support %w[layer1 RegionA-Acc01 p4]
        end
        term_point 'p3' do
          support %w[layer1 RegionA-Acc01 p6]
        end
        support %w[layer15 RegionA-Acc01]
      end
      node 'RegionA-Acc01-VL110' do
        term_point 'p0' do
          support %w[layer15 RegionA-Acc01 p01]
        end
        term_point 'p1' do
          support %w[layer15 RegionA-Acc01 p23]
        end
        term_point 'p2' do
          support %w[layer1 RegionA-Acc01 p5]
        end
        term_point 'p3' do
          support %w[layer1 RegionA-Acc01 p7]
        end
        support %w[layer15 RegionA-Acc01]
      end

      node 'RegionA-Svr01' do
        (0..1).each do |i|
          term_point "eno#{i}" do
            support %W[layer1 RegionA-Svr01 eno#{i}]
          end
        end
        support %w[layer1 RegionA-Svr01]
      end
      node 'RegionA-Svr02' do
        (0..1).each do |i|
          term_point "eno#{i}" do
            support %W[layer1 RegionA-Svr02 eno#{i}]
          end
        end
        support %w[layer1 RegionA-Svr02]
      end

      # RegionA Links
      bdlink %w[RegionA-CE01-GRT p0 RegionA-CE01-VL10 p0]
      bdlink %w[RegionA-CE01-GRT p1 RegionA-CE01-VL20 p0]

      bdlink %w[RegionA-CE01-VRF p0 RegionA-CE01-VL110 p0]
      bdlink %w[RegionA-CE01-VRF p1 RegionA-CE01-VL120 p0]

      bdlink %w[RegionA-CE02-GRT p0 RegionA-CE02-VL10 p0]
      bdlink %w[RegionA-CE02-GRT p1 RegionA-CE02-VL20 p0]

      bdlink %w[RegionA-CE02-VRF p0 RegionA-CE02-VL110 p0]
      bdlink %w[RegionA-CE02-VRF p1 RegionA-CE02-VL120 p0]

      bdlink %w[RegionA-CE01-VL10 p2 RegionA-CE02-VL10 p2]
      bdlink %w[RegionA-CE01-VL110 p2 RegionA-CE02-VL110 p2]
      bdlink %w[RegionA-CE01-VL20 p1 RegionA-CE02-VL20 p1]
      bdlink %w[RegionA-CE01-VL120 p1 RegionA-CE02-VL120 p1]

      bdlink %w[RegionA-CE01-VL10 p1 RegionA-Acc01-VL10 p0]
      bdlink %w[RegionA-CE01-VL110 p1 RegionA-Acc01-VL110 p0]

      bdlink %w[RegionA-CE02-VL10 p1 RegionA-Acc01-VL10 p1]
      bdlink %w[RegionA-CE02-VL110 p1 RegionA-Acc01-VL110 p1]

      bdlink %w[RegionA-Acc01-VL10 p2 RegionA-Svr01 eno0]
      bdlink %w[RegionA-Acc01-VL10 p3 RegionA-Svr02 eno0]
      bdlink %w[RegionA-Acc01-VL110 p2 RegionA-Svr01 eno1]
      bdlink %w[RegionA-Acc01-VL110 p3 RegionA-Svr02 eno1]

      # RegionB Nodes
      node 'RegionB-CE01-GRT' do
        (0..1).each { |i| term_point "p#{i}" }
        support %w[layer15 RegionB-CE01]
      end
      node 'RegionB-CE01-VRF' do
        (0..1).each { |i| term_point "p#{i}" }
        support %w[layer15 RegionB-CE01]
      end

      node 'RegionB-CE02-GRT' do
        (0..1).each { |i| term_point "p#{i}" }
        support %w[layer15 RegionB-CE02]
      end
      node 'RegionB-CE02-VRF' do
        (0..1).each { |i| term_point "p#{i}" }
        support %w[layer15 RegionB-CE02]
      end

      node 'RegionB-CE01-VL10' do
        term_point 'p0'
        term_point 'p1' do
          support %w[layer15 RegionB-CE01 p45]
        end
        term_point 'p2' do
          support %w[layer15 RegionB-CE01 p01]
        end
        support %w[layer15 RegionB-CE01]
      end
      node 'RegionB-CE01-VL20' do
        term_point 'p0'
        term_point 'p1' do
          support %w[layer15 RegionB-CE01 p45]
        end
        term_point 'p2' do
          support %w[layer15 RegionB-CE01 p01]
        end
        support %w[layer15 RegionB-CE01]
      end
      node 'RegionB-CE01-VL110' do
        term_point 'p0'
        term_point 'p1' do
          support %w[layer15 RegionB-CE01 p45]
        end
        term_point 'p2' do
          support %w[layer15 RegionB-CE01 p01]
        end
        support %w[layer15 RegionB-CE01]
      end
      node 'RegionB-CE01-VL120' do
        term_point 'p0'
        term_point 'p1' do
          support %w[layer15 RegionB-CE01 p45]
        end
        term_point 'p2' do
          support %w[layer15 RegionB-CE01 p01]
        end
        support %w[layer15 RegionB-CE01]
      end

      node 'RegionB-CE02-VL10' do
        term_point 'p0'
        term_point 'p1' do
          support %w[layer15 RegionB-CE02 p45]
        end
        term_point 'p2' do
          support %w[layer15 RegionB-CE02 p01]
        end
        support %w[layer15 RegionB-CE02]
      end
      node 'RegionB-CE02-VL20' do
        term_point 'p0'
        term_point 'p1' do
          support %w[layer15 RegionB-CE02 p01]
        end
        support %w[layer15 RegionB-CE02]
      end
      node 'RegionB-CE02-VL110' do
        term_point 'p0'
        term_point 'p1' do
          support %w[layer15 RegionB-CE02 p45]
        end
        term_point 'p2' do
          support %w[layer15 RegionB-CE02 p01]
        end
        support %w[layer15 RegionB-CE02]
      end
      node 'RegionB-CE02-VL120' do
        term_point 'p0'
        term_point 'p1' do
          support %w[layer15 RegionB-CE02 p01]
        end
        support %w[layer15 RegionB-CE02]
      end

      node 'RegionB-Acc01-VL10' do
        term_point 'p0' do
          support %w[layer15 RegionB-Acc01 p01]
        end
        term_point 'p1' do
          support %w[layer15 RegionB-Acc01 p23]
        end
        term_point 'p2' do
          support %w[layer1 RegionB-Acc01 p4]
        end
        support %w[layer15 RegionB-Acc01]
      end
      node 'RegionB-Acc01-VL110' do
        term_point 'p0' do
          support %w[layer15 RegionB-Acc01 p01]
        end
        term_point 'p1' do
          support %w[layer15 RegionB-Acc01 p23]
        end
        term_point 'p2' do
          support %w[layer1 RegionB-Acc01 p5]
        end
        support %w[layer15 RegionB-Acc01]
      end

      node 'RegionB-Acc02-VL20' do
        term_point 'p0' do
          support %w[layer15 RegionB-Acc02 p01]
        end
        term_point 'p1' do
          support %w[layer15 RegionB-Acc02 p23]
        end
        term_point 'p2' do
          support %w[layer1 RegionB-Acc02 p4]
        end
        support %w[layer15 RegionB-Acc02]
      end
      node 'RegionB-Acc02-VL120' do
        term_point 'p0' do
          support %w[layer15 RegionB-Acc02 p01]
        end
        term_point 'p1' do
          support %w[layer15 RegionB-Acc02 p23]
        end
        term_point 'p2' do
          support %w[layer1 RegionB-Acc02 p5]
        end
        support %w[layer15 RegionB-Acc02]
      end

      node 'RegionB-Svr01' do
        (0..1).each do |i|
          term_point "eno#{i}" do
            support %W[layer1 RegionB-Svr01 eno#{i}]
          end
        end
        support %w[layer1 RegionB-Svr01]
      end
      node 'RegionB-Svr02' do
        (0..1).each do |i|
          term_point "eno#{i}" do
            support %W[layer1 RegionB-Svr02 eno#{i}]
          end
        end
        support %w[layer1 RegionB-Svr02]
      end

      # RegionB Links
      bdlink %w[RegionB-CE01-GRT p0 RegionB-CE01-VL10 p0]
      bdlink %w[RegionB-CE01-GRT p1 RegionB-CE01-VL20 p0]

      bdlink %w[RegionB-CE01-VRF p0 RegionB-CE01-VL110 p0]
      bdlink %w[RegionB-CE01-VRF p1 RegionB-CE01-VL120 p0]

      bdlink %w[RegionB-CE02-GRT p0 RegionB-CE02-VL10 p0]
      bdlink %w[RegionB-CE02-GRT p1 RegionB-CE02-VL20 p0]

      bdlink %w[RegionB-CE02-VRF p0 RegionB-CE02-VL110 p0]
      bdlink %w[RegionB-CE02-VRF p1 RegionB-CE02-VL120 p0]

      bdlink %w[RegionB-CE01-VL10 p2 RegionB-CE02-VL10 p2]
      bdlink %w[RegionB-CE01-VL110 p2 RegionB-CE02-VL110 p2]
      bdlink %w[RegionB-CE01-VL20 p1 RegionB-CE02-VL20 p1]
      bdlink %w[RegionB-CE01-VL120 p1 RegionB-CE02-VL120 p1]

      bdlink %w[RegionB-CE01-VL10 p1 RegionB-Acc01-VL10 p0]
      bdlink %w[RegionB-CE01-VL20 p1 RegionB-Acc02-VL20 p0]
      bdlink %w[RegionB-CE01-VL110 p1 RegionB-Acc01-VL110 p0]
      bdlink %w[RegionB-CE01-VL120 p1 RegionB-Acc02-VL120 p0]

      bdlink %w[RegionB-CE02-VL10 p1 RegionB-Acc01-VL10 p1]
      bdlink %w[RegionB-CE02-VL20 p1 RegionB-Acc02-VL20 p1]
      bdlink %w[RegionB-CE02-VL110 p1 RegionB-Acc01-VL110 p1]
      bdlink %w[RegionB-CE02-VL120 p1 RegionB-Acc02-VL120 p1]

      bdlink %w[RegionB-Acc01-VL10 p2 RegionB-Svr01 eno0]
      bdlink %w[RegionB-Acc01-VL110 p2 RegionB-Svr01 eno1]

      bdlink %w[RegionB-Acc02-VL20 p2 RegionB-Svr02 eno0]
      bdlink %w[RegionB-Acc02-VL120 p2 RegionB-Svr02 eno1]
    end
  end
end
# rubocop:enable Metrics/MethodLength, Metrics/AbcSize
