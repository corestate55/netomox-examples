require 'netomox'

# rubocop:disable Metrics/MethodLength, Metrics/BlockLength, Metrics/AbcSize
def register_target_layer3(nws)
  nws.register do
    network 'target-L3' do
      type Netomox::NWTYPE_L3
      support 'target-L2a'
      support 'target-L2b'
      attribute(
        name: 'L3 of target network',
        flags: %w[layer3 unicast]
      )

      seg_a_prefix = { prefix: '192.168,10.0/24', metric: 100 }
      seg_b_prefix = { prefix: '192.168.20.0/24', metric: 100 }
      seg_c_prefix = { prefix: '192.168.30.0/24', metric: 100 }

      node 'R1-GRT' do
        attribute(
          prefixes: [seg_a_prefix, seg_b_prefix],
          router_id: '192.168.0.1'
        )
        term_point 'p1' do
          attribute(ip_addrs: ['192.168.10.253'])
          support %w[target-L2a R1-GRT p1]
        end
        term_point 'p2' do
          attribute(ip_addrs: ['192.168.20.253'])
          support %w[target-L2a R1-GRT p1]
        end
        support %w[target-L2a R1-GRT]
      end

      node 'R2-GRT' do
        attribute(
          prefixes: [seg_a_prefix, seg_b_prefix],
          router_id: '192.168.0.2'
        )
        term_point 'p1' do
          attribute(ip_addrs: ['192.168.10.252'])
          support %w[target-L2a R2-GRT p1]
        end
        term_point 'p2' do
          attribute(ip_addrs: ['192.168.20.252'])
          support %w[target-L2a R2-GRT p1]
        end
        support %w[target-L2a R2-GRT]
      end

      node 'Seg.A' do
        attribute(
          prefixes: [seg_a_prefix],
          flags: %w[l3-segment pseudo-node]
        )
        term_point 'p1' do
          support %w[target-L2a R1-BR-VL10 p1]
        end
        term_point 'p2' do
          support %w[target-L2a R2-BR-VL10 p1]
        end
        term_point 'p3' do
          support %w[target-L2a HYP1-vSW1-BR-VL10 p3]
        end
        term_point 'p4' do
          support %w[target-L2a SW2-BR-VL10 p4]
        end
        support %w[target-L2a R1-BR-VL10]
        support %w[target-L2a R2-BR-VL10]
        support %w[target-L2a SW1-BR-VL10]
        support %w[target-L2a SW2-BR-VL10]
        support %w[target-L2a HYP1-vSW1-BR-VL10]
      end

      node 'Seg.B' do
        attribute(
          prefixes: [seg_b_prefix],
          flags: %w[l3-segment pseudo-node]
        )
        term_point 'p1' do
          support %w[target-L2a R1-BR-VL10 p1]
        end
        term_point 'p2' do
          support %w[target-L2a R2-BR-VL10 p1]
        end
        term_point 'p3' do
          support %w[target-L2a HYP1-vSW1-BR-VL10 p4]
        end
        term_point 'p4' do
          support %w[target-L2a SW2-BR-VL10 p5]
        end
        support %w[target-L2a R1-BR-VL10]
        support %w[target-L2a R2-BR-VL10]
        support %w[target-L2a SW1-BR-VL10]
        support %w[target-L2a SW2-BR-VL10]
        support %w[target-L2a HYP1-vSW1-BR-VL10]
      end

      node 'Seg.C' do
        attribute(
          prefixes: [seg_c_prefix],
          flags: %w[l3-segment pseudo-node]
        )
        term_point 'p1' do
          support %w[target-L2b HYP1-vSW1-BR-VL30 p1]
        end
        term_point 'p2' do
          support %w[target-L2b SW2-BR-VL30 p3]
        end
        support %w[target-L2b SW1-BR-VL30]
        support %w[target-L2b SW2-BR-VL30]
        support %w[target-L2b HYP1-vSW1-BR-VL30]
      end

      node 'VM1' do
        attribute(prefixes: [seg_a_prefix])
        term_point 'eth0' do
          attribute(ip_addrs: ['192.168.10.11'])
          support %w[target-L2a VM1 eth0]
        end
        support %w[target-L2a VM1]
      end

      node 'VM2' do
        attribute(prefixes: [seg_b_prefix, seg_c_prefix])
        term_point 'eth0.20' do
          attribute(ip_addrs: ['192.168.20.2'])
          support %w[target-L2a VM2 eth0.20]
        end
        term_point 'eth0.30' do
          attribute(ip_addrs: ['192.168.30.2'])
          support %w[target-L2b VM2 eth0.30]
        end
        support %w[target-L2a VM2]
        support %w[target-L2b VM2]
      end

      node 'SV1' do
        attribute(prefixes: [seg_a_prefix])
        term_point 'eth0' do
          attribute(ip_addrs: ['192.168.10.31'])
          support %w[target-L2a SV1 eth0]
        end
        support %w[target-L2a SV1]
      end

      node 'SV2' do
        attribute(prefixes: [seg_b_prefix, seg_c_prefix])
        term_point 'eth0.20' do
          attribute(ip_addrs: ['192.168.20.4'])
          support %w[target-L2a SV2 eth0.20]
        end
        term_point 'eth0.30' do
          attribute(ip_addrs: ['192.168.30.4'])
          support %w[target-L2b SV2 eth0.30]
        end
        support %w[target-L2a SV2]
        support %w[target-L2b SV2]
      end

      bdlink %w[R1-GRT p1 Seg.A p1]
      bdlink %w[R1-GRT p2 Seg.B p1]
      bdlink %w[R2-GRT p1 Seg.A p2]
      bdlink %w[R2-GRT p2 Seg.B p2]
      bdlink %w[Seg.A p3 VM1 eth0]
      bdlink %w[Seg.B p3 VM2 eth0.20]
      bdlink %w[Seg.A p4 SV1 eth0]
      bdlink %w[Seg.B p4 SV2 eth0.20]
      bdlink %w[VM2 eth0.30 Seg.C p1]
      bdlink %w[SV2 eth0.30 Seg.C p2]
    end
  end
end
# rubocop:enable Metrics/MethodLength, Metrics/BlockLength, Metrics/AbcSize
