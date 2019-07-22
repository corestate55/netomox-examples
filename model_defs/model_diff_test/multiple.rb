# frozen_string_literal: true

require 'json'
require 'netomox'

model_dir = 'model_defs/model/'

test_nws1 = Netomox::DSL::Networks.new do
  network 'layer1' do
    sw1 = node 'sw1'
    sv1 = node 'sv1'
    sv2 = node 'sv2'
    sw1.tp_prefix = 'gi'
    sv1.tp_prefix = 'eth'
    sv2.tp_prefix = 'eth'
    sw1.bdlink_to(sv1)
    sw1.bdlink_to(sv2)
  end

  network 'layer3' do
    seg_a_prefix = { prefix: '192.168,10.0/24', metric: 100 }
    seg_b_prefix = { prefix: '192.168.20.0/24', metric: 100 }
    seg_c_prefix = { prefix: '192.168.30.0/24', metric: 100 }
    pref_a = { prefixes: [seg_a_prefix] }
    pref_b = { prefixes: [seg_b_prefix] }
    pref_c = { prefixes: [seg_c_prefix] }
    pref_ab = { prefixes: [seg_a_prefix, seg_b_prefix] }
    pref_bc = { prefixes: [seg_b_prefix, seg_c_prefix] }

    type Netomox::NWTYPE_L3
    support 'layer1'

    node 'seg_a' do
      attribute(pref_a)
      support %w[layer1 sw1]
      term_point 'p0' do
        support %w[layer1 sw1 gi0]
      end
      term_point 'p1' do
        support %w[layer1 sw1 gi0]
      end
    end
    node 'seg_b' do
      support %w[layer1 sw1]
      attribute(pref_b)
      term_point 'p0' do
        support %w[layer1 sw1 gi0]
      end
      term_point 'p1' do
        support %w[layer1 sw1 gi1]
      end
    end
    node 'seg_c' do
      support %w[layer1 sv2]
      attribute(pref_c)
      term_point 'p0'
    end
    node 'vm1' do
      attribute(pref_a)
      support %w[layer1 sv1]
      term_point 'eth0' do
        support %w[layer1 sv1 eth0]
      end
    end
    node 'vm2' do
      attribute(pref_ab)
      support %w[layer1 sv1]
      term_point 'eth0' do
        support %w[layer1 sv1 eth0]
      end
      term_point 'eth1' do
        support %w[layer1 sv1 eth0]
      end
    end
    node 'vm3' do
      attribute(pref_bc)
      support %w[layer1 sv2]
      term_point 'eth0' do
        support %w[layer1 sv2 eth0]
      end
      term_point 'eth1'
    end
    bdlink %w[vm1 eth0 seg_a p0]
    bdlink %w[seg_a p1 vm2 eth0]
    bdlink %w[vm2 eth1 seg_b p0]
    bdlink %w[seg_b p1 vm3 eth0]
    bdlink %w[vm3 eth1 seg_c p0]
  end
end

test_nws2 = Netomox::DSL::Networks.new do
  network 'layer1' do
    sw1 = node 'sw1'
    sv1 = node 'sv1'
    sv2 = node 'sv2'
    sw1.tp_prefix = 'gi'
    sv1.tp_prefix = 'eth'
    sv2.tp_prefix = 'eth'
    sw1.bdlink_to(sv1)
    sw1.bdlink_to(sv2)
  end

  network 'layer3' do
    seg_a_prefix = { prefix: '192.168,10.0/24', metric: 100 }
    seg_b_prefix = { prefix: '192.168.20.0/24', metric: 100 }
    seg_c_prefix = { prefix: '192.168.30.0/24', metric: 100 }
    pref_a = { prefixes: [seg_a_prefix] }
    pref_b = { prefixes: [seg_b_prefix] }
    pref_c = { prefixes: [seg_c_prefix] }
    pref_ab = { prefixes: [seg_a_prefix, seg_b_prefix] }
    pref_bc = { prefixes: [seg_b_prefix, seg_c_prefix] }

    type Netomox::NWTYPE_L3
    support 'layer1'

    node 'seg_c' do
      support %w[layer1 sv2]
      attribute(pref_c)
      term_point 'p0'
      term_point 'p1'
    end
    node 'seg_a' do
      attribute(pref_a)
      support %w[layer1 sw1]
      term_point 'p0' do
        support %w[layer1 sw1 gi0]
      end
    end
    node 'seg_b' do
      support %w[layer1 sw1]
      attribute(pref_b)
      term_point 'p0' do
        support %w[layer1 sw1 gi0]
      end
      term_point 'p1' do
        support %w[layer1 sw1 gi1]
      end
    end
    node 'vm1' do
      attribute(pref_ab)
      support %w[layer1 sv1]
      term_point 'eth0' do
        support %w[layer1 sv1 eth0]
      end
      term_point 'eth1' do
        support %w[layer1 sv1 eth0]
      end
    end
    node 'vm3' do
      attribute(pref_bc)
      support %w[layer1 sv2]
      term_point 'eth0' do
        support %w[layer1 sv2 eth0]
      end
      term_point 'eth1'
    end
    node 'vm4' do
      attribute(pref_c)
      support %w[layer1 sv2]
      term_point 'eth0'
    end
    bdlink %w[seg_a p0 vm1 eth0]
    bdlink %w[vm1 eth1 seg_b p0]
    bdlink %w[seg_b p1 vm3 eth0]
    bdlink %w[vm3 eth1 seg_c p0]
    bdlink %w[seg_c p1 vm4 eth0]
  end
end

File.open("#{model_dir}/test_multiple1.json", 'w') do |file|
  file.write(JSON.pretty_generate(test_nws1.topo_data))
end

File.open("#{model_dir}/test_multiple2.json", 'w') do |file|
  file.write(JSON.pretty_generate(test_nws2.topo_data))
end
