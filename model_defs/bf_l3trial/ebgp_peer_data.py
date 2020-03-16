import argparse
import pandas as pd
from os import path

parser = argparse.ArgumentParser()
parser.add_argument('csv_dir', help='Path of batfish csv directory.')
parser.add_argument('-d', '--debug', help='Enable debug print.')
args = parser.parse_args()

csv_dir = args.csv_dir
edges_bgp = pd.read_csv(path.join(csv_dir, 'edges_bgp.csv'))
config_bgp_peer = pd.read_csv(path.join(csv_dir, 'config_bgp_peer.csv'))
# remove records that has 'NaN' value at columns as `subset`.
config_bgp_peer = config_bgp_peer.dropna(subset=['Local_IP'])
config_bgp_proc = pd.read_csv(path.join(csv_dir, 'config_bgp_proc.csv'))
edges_layer3 = pd.read_csv(path.join(csv_dir, 'edges_layer3.csv'))
ip_owners = pd.read_csv(path.join(csv_dir, 'ip_owners.csv'))


def make_bgp_proc_record(index, node, router_id, remote_ip):
    return pd.DataFrame(
        index=[index, ],
        data={
            'Node': node,
            'VRF': 'default',
            'Router_ID': router_id,
            'Confederation_ID': None,
            'Confederation_Members': None,
            'Multipath_EBGP': False,
            'Multipath_IBGP': False,
            'Multipath_Match_Mode': None,
            'Neighbors': str([remote_ip]),
            'Route_Reflector': False,
            'Tie_Breaker': 'ARRIVAL_OERDER'},
        columns=[
            'Node',
            'VRF',
            'Router_ID',
            'Confederation_ID',
            'Confederation_Members',
            'Multipath_EBGP',
            'Multipath_IBGP',
            'Multipath_Match_Mode',
            'Neighbors',
            'Route_Reflector',
            'Tie_Breaker']
    )


def make_edges_bgp_record(
        index, node, local_as, local_ip, remote_node, remote_as, remote_ip):
    return pd.DataFrame(
        index=[index, ],
        data={
            'Node': node,
            'IP': local_ip,
            'Interface': None,
            'AS_Number': local_as,
            'Remote_Node': remote_node,
            'Remote_IP': remote_ip,
            'Remote_Interface': None,
            'Remote_AS_Number': remote_as},
        columns=[
            'Node',
            'IP',
            'Interface',
            'AS_Number',
            'Remote_Node',
            'Remote_IP',
            'Remote_Interface',
            'Remote_AS_Number']
    )


def make_edges_l3_record(
        index, node, interface, ips, remote_node, remote_interface, remote_ips):
    remote_ip_list = remote_ips if isinstance(remote_ips, list) else [remote_ips]
    local_ip_list = ips if isinstance(ips, list) else [ips]
    return pd.DataFrame(
        index=[index, ],
        data={
            'index': index,
            'Interface': node + '[' + interface + ']',
            'IPs': str(local_ip_list),
            'Remote_Interface': remote_node + '[' + remote_interface + ']',
            'Remote_IPs': str(remote_ip_list)},
        columns=['index', 'Interface', 'IPs', 'Remote_Interface', 'Remote_IPs']
    )


def make_ip_owners_record(index, node, vrf, interface, ip, mask, active):
    return pd.DataFrame(
        index=[index, ],
        data={
            'index': index,
            'Node': node,
            'VRF': vrf,
            'Interface': interface,
            'IP': ip,
            'Mask': mask,
            'Active': active},
        columns=['index', 'Node', 'VRF', 'Interface', 'IP', 'Mask', 'Active']
    )


def bgp_peer_loc(row_number, column_name):
    column_number = config_bgp_peer.columns.get_loc(column_name)
    return str(config_bgp_peer.iloc[row_number, column_number])


def as_peer_str(asn, peer):
    return asn + '_' + peer


def ip_query(ip, column):
    return ip_owners.query('IP == "' + ip + '"')[column].values[0]


for i, bgp_peer in enumerate(config_bgp_peer['Remote_IP']):
    count_list = edges_bgp['Remote_IP'].tolist()
    if ((count_list.count(bgp_peer) > 0) or
            (bgp_peer_loc(i, 'Local_AS') == bgp_peer_loc(i, 'Remote_AS'))):
        continue

    target_node = bgp_peer_loc(i, 'Node')
    target_remote_as = bgp_peer_loc(i, 'Remote_AS')
    target_remote_ip = bgp_peer_loc(i, 'Remote_IP')
    target_local_as = bgp_peer_loc(i, 'Local_AS')
    target_local_ip = bgp_peer_loc(i, 'Local_IP')

    # debug
    print("node:%s, ras:%s, rip:%s, las:%s, lip:%s" %
          (target_node, target_remote_as, target_remote_ip, target_local_as, target_local_ip))

    config_bgp_proc = config_bgp_proc.append(
        make_bgp_proc_record(
            index=len(config_bgp_proc['Node']),
            node=as_peer_str(target_remote_as, bgp_peer),
            router_id=as_peer_str(target_remote_as, bgp_peer),
            # Local_AS=target_remote_as,
            # Local_IP=bgp_peer,
            # Remote_AS=target_local_as,
            remote_ip=target_local_ip),
        ignore_index=True,
        sort=True)
    edges_bgp = edges_bgp.append(
        make_edges_bgp_record(
            index=len(edges_bgp['Node']),
            node=target_node,
            local_as=target_local_as,
            local_ip=target_local_ip,
            remote_node=as_peer_str(target_remote_as, bgp_peer),
            remote_as=target_remote_as,
            remote_ip=target_remote_ip),
        sort=True)

    edges_bgp = edges_bgp.append(
        make_edges_bgp_record(
            index=len(edges_bgp['Node']),
            node=as_peer_str(target_remote_as, bgp_peer),
            local_as=target_remote_as,
            local_ip=target_remote_ip,
            remote_node=target_node,
            remote_as=target_local_as,
            remote_ip=target_local_ip),
        sort=True)
    ip_owners = ip_owners.append(
        make_ip_owners_record(
            index=len(ip_owners['IP']),
            node=as_peer_str(target_remote_as, bgp_peer),
            vrf="default",
            interface=target_remote_ip,
            ip=target_remote_ip,
            mask=ip_query(target_local_ip, 'Mask'),
            active="True"),
        sort=True)

    edges_layer3 = edges_layer3.append(
        make_edges_l3_record(
            index=len(edges_layer3['IPs']),
            node=target_node,
            interface=ip_query(target_local_ip, 'Interface'),
            ips=target_local_ip,
            remote_node=ip_query(target_remote_ip, 'Node'),
            remote_interface=target_remote_ip,
            remote_ips=target_remote_ip),
        sort=True)

    edges_layer3 = edges_layer3.append(
        make_edges_l3_record(
            index=len(edges_layer3['IPs']),
            node=ip_query(target_remote_ip, 'Node'),
            interface=target_remote_ip,
            ips=target_remote_ip,
            remote_node=target_node,
            remote_interface=ip_query(target_local_ip, 'Interface'),
            remote_ips=target_local_ip),
        sort=True)


# debug
if args.debug:
    print(config_bgp_proc)
    print(edges_bgp)
    print(edges_layer3)
    print(ip_owners)

# save data as csv
csv_post = '_ep'  # complemented ebgp-peer
config_bgp_proc.to_csv(path.join(csv_dir, "config_bgp_proc%s.csv" % csv_post))
edges_bgp.to_csv(path.join(csv_dir, "edges_bgp%s.csv" % csv_post))
edges_layer3.to_csv(path.join(csv_dir, "edges_layer3%s.csv" % csv_post))
ip_owners.to_csv(path.join(csv_dir, "ip_owners%s.csv" % csv_post))
