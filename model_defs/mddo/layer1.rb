# frozen_string_literal: true

require 'netomox'

# rubocop:disable Metrics/MethodLength, Metrics/AbcSize
def register_target_layer1(nws)
  nws.register do
    network 'layer1' do
      # RegionA Nodes
      node 'RegionA-PE01' do
        (0..3).each { |i| term_point "p#{i}" }
      end
      node 'RegionA-PE02' do
        (0..3).each { |i| term_point "p#{i}" }
      end

      node 'RegionA-CE01' do
        (0..5).each { |i| term_point "p#{i}" }
      end
      node 'RegionA-CE02' do
        (0..5).each { |i| term_point "p#{i}" }
      end

      node 'RegionA-Acc01' do
        (0..7).each { |i| term_point "p#{i}" }
      end

      node 'RegionA-Svr01' do
        (0..1).each { |i| term_point "eno#{i}" }
      end
      node 'RegionA-Svr02' do
        (0..1).each { |i| term_point "eno#{i}" }
      end

      # RegionA Links
      bdlink %w[RegionA-PE01 p0 RegionA-PE02 p0]
      bdlink %w[RegionA-PE01 p2 RegionA-CE01 p2]
      bdlink %w[RegionA-PE01 p3 RegionA-CE02 p2]

      bdlink %w[RegionA-PE02 p2 RegionA-CE01 p3]
      bdlink %w[RegionA-PE02 p3 RegionA-CE02 p3]

      bdlink %w[RegionA-CE01 p0 RegionA-CE02 p0]
      bdlink %w[RegionA-CE01 p1 RegionA-CE02 p1]

      bdlink %w[RegionA-CE01 p4 RegionA-Acc01 p0]
      bdlink %w[RegionA-CE01 p5 RegionA-Acc01 p1]

      bdlink %w[RegionA-CE02 p4 RegionA-Acc01 p2]
      bdlink %w[RegionA-CE02 p5 RegionA-Acc01 p3]

      bdlink %w[RegionA-Acc01 p4 RegionA-Svr01 eno0]
      bdlink %w[RegionA-Acc01 p5 RegionA-Svr01 eno1]
      bdlink %w[RegionA-Acc01 p6 RegionA-Svr02 eno0]
      bdlink %w[RegionA-Acc01 p7 RegionA-Svr02 eno1]

      # RegionB Nodes
      node 'RegionB-PE01' do
        (0..3).each { |i| term_point "p#{i}" }
      end
      node 'RegionB-PE02' do
        (0..3).each { |i| term_point "p#{i}" }
      end

      node 'RegionB-CE01' do
        (0..7).each { |i| term_point "p#{i}" }
      end
      node 'RegionB-CE02' do
        (0..7).each { |i| term_point "p#{i}" }
      end

      node 'RegionB-Acc01' do
        (0..5).each { |i| term_point "p#{i}" }
      end
      node 'RegionB-Acc02' do
        (0..5).each { |i| term_point "p#{i}" }
      end

      node 'RegionB-Svr01' do
        (0..1).each { |i| term_point "eno#{i}" }
      end
      node 'RegionB-Svr02' do
        (0..1).each { |i| term_point "eno#{i}" }
      end

      # RegionB Links
      bdlink %w[RegionB-PE01 p0 RegionB-PE02 p0]
      bdlink %w[RegionB-PE01 p2 RegionB-CE01 p2]
      bdlink %w[RegionB-PE01 p3 RegionB-CE02 p2]

      bdlink %w[RegionB-PE02 p2 RegionB-CE01 p3]
      bdlink %w[RegionB-PE02 p3 RegionB-CE02 p3]

      bdlink %w[RegionB-CE01 p0 RegionB-CE02 p0]
      bdlink %w[RegionB-CE01 p1 RegionB-CE02 p1]

      bdlink %w[RegionB-CE01 p4 RegionB-Acc01 p0]
      bdlink %w[RegionB-CE01 p5 RegionB-Acc01 p1]
      bdlink %w[RegionB-CE01 p6 RegionB-Acc02 p0]
      bdlink %w[RegionB-CE01 p7 RegionB-Acc02 p1]

      bdlink %w[RegionB-CE02 p4 RegionB-Acc01 p2]
      bdlink %w[RegionB-CE02 p5 RegionB-Acc01 p3]
      bdlink %w[RegionB-CE02 p6 RegionB-Acc02 p2]
      bdlink %w[RegionB-CE02 p7 RegionB-Acc02 p3]

      bdlink %w[RegionB-Acc01 p4 RegionB-Svr01 eno0]
      bdlink %w[RegionB-Acc01 p5 RegionB-Svr01 eno1]
      bdlink %w[RegionB-Acc02 p4 RegionB-Svr02 eno0]
      bdlink %w[RegionB-Acc02 p5 RegionB-Svr02 eno1]

      # Inter Region Links
      bdlink %w[RegionA-PE01 p1 RegionB-PE01 p1]
      bdlink %w[RegionA-PE02 p1 RegionB-PE02 p1]
    end
  end
end
# rubocop:enable Metrics/MethodLength, Metrics/AbcSize
