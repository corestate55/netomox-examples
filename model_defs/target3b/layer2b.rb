require 'netomox'

# rubocop:disable Metrics/MethodLength, Metrics/BlockLength, Metrics/AbcSize
def register_target_layer2b(nws)
  nws.register do
    network 'target-L2b' do
      type Netomox::NWTYPE_L2
      support 'target-L1'
      support 'target-L1.5'
      attribute(
        name: 'L2 (VLAN30) of target network',
        flags: ['layer2']
      )

      vlan_c = { id: 30, name: 'Seg.C' }
      trunk_vlan_c = {
        eth_encap: '802.1q',
        vlan_id_names: [vlan_c]
      }

      node 'SW1-BR-VL30' do
        attribute(
          name: 'SW1-BR',
          descr: 'L2 bridge of SW1',
          mgmt_addrs: %w[192.168.10.1],
          mgmt_vid: 10
        )
        term_point 'p1' do
          attribute(trunk_vlan_c)
          support %w[target-L1 SW1 Fa2]
        end
        term_point 'p2' do
          attribute(trunk_vlan_c)
          support %w[target-L1 SW1 Fa0]
        end
        support %w[target-L1 SW1]
      end

      node 'SW2-BR-VL30' do
        attribute(
          name: 'SW2-BR',
          descr: 'L2 bridge of SW2',
          mgmt_addrs: %w[192.168.10.2],
          mgmt_vid: 10
        )
        term_point 'p1' do
          attribute(trunk_vlan_c)
          support %w[target-L1 SW2 Fa2]
        end
        term_point 'p2' do
          attribute(trunk_vlan_c)
          support %w[target-L1 SW2 Fa0]
        end
        term_point 'p3' do
          attribute(trunk_vlan_c)
          support %w[target-L1 SW2 Fa4]
        end
        support %w[target-L1 SW2]
      end

      node 'HYP1-vSW1-BR-VL30' do
        term_point 'p1' do
          attribute(trunk_vlan_c)
          support %w[target-L1.5 HYP1-vSW1 eth0]
        end
        term_point 'p2' do
          attribute(trunk_vlan_c)
          support %w[target-L1.5 HYP1-vSW1 eth1]
        end
        term_point 'p3' do
          attribute(trunk_vlan_c)
          support %w[target-L1.5 HYP1-vSW1 p2]
        end
        support %w[target-L1.5 HYP1-vSW1]
      end

      node 'VM2' do
        term_point 'eth0.30' do
          attribute(trunk_vlan_c)
          support %w[target-L1.5 VM2 eth0]
        end
        support %w[target-L1.5 VM2]
      end

      node 'SV2' do
        term_point 'eth0.30' do
          attribute(trunk_vlan_c)
          support %w[target-L1 SV2 eth0]
        end
        support %w[target-L1 SV2]
      end

      bdlink %w[SW1-BR-VL30 p2 SW2-BR-VL30 p2]
      bdlink %w[SW1-BR-VL30 p1 HYP1-vSW1-BR-VL30 p1]
      bdlink %w[SW2-BR-VL30 p1 HYP1-vSW1-BR-VL30 p2]
      bdlink %w[SW2-BR-VL30 p3 SV2 eth0.30]
      bdlink %w[HYP1-vSW1-BR-VL30 p3 VM2 eth0.30]
    end
  end
end
# rubocop:enable Metrics/MethodLength, Metrics/BlockLength, Metrics/AbcSize
