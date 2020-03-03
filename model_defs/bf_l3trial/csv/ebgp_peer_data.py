import pandas as pd

edges_bgp = pd.read_csv("edges_bgp.csv")
config_bgp_peer = pd.read_csv("config_bgp_peer.csv")
config_bgp_proc = pd.read_csv("config_bgp_proc.csv")
edges_layer3 = pd.read_csv("edges_layer3.csv")
ip_owners = pd.read_csv("ip_owners.csv")


def func_bgp_proc(index, Node, Router_ID, Local_AS,
                  Local_IP, Remote_AS, Remote_IP):
    tmplist = []
    tmplist.append(Remote_IP)
    return pd.DataFrame(
        index=[index, ],
        data={
            'Node': Node,
            'VRF': 'default',
            'Router_ID': Router_ID,
            'Confederation_ID': None,
            'Confederation_Members': None,
            'Multipath_EBGP': False,
            'Multipath_IBGP': False,
            'Multipath_Match_Mode': None,
            'Neighbors': str(tmplist),
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


def func_edges_bgp(index, Node, Local_AS, Local_IP,
                   Remote_Node, Remote_AS, Remote_IP):
    return pd.DataFrame(
        index=[index, ],
        data={
            'Node': Node,
            'IP': Local_IP,
            'Interface': None,
            'AS_Number': Local_AS,
            'Remote_Node': Remote_Node,
            'Remote_IP': Remote_IP,
            'Remote_Interface': None,
            'Remote_AS_Number': Remote_AS},
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


def func_edges_l3(index, Node, Interface, IPs, Remote_Node,
                  Remote_Interface, Remote_IPs):
    Remotelist = []
    Remotelist.append(Remote_IPs)
    LocalIPlist = []
    LocalIPlist.append(IPs)
    return pd.DataFrame(
        index=[index, ],
        data={
            'index': index,
            'Interface': Node + '[' + Interface + ']',
            'IPs': str(LocalIPlist),
            'Remote_Interface': Remote_Node + '[' + Remote_Interface + ']',
            'Remote_IPs': str(Remotelist)},
        columns=['index', 'Interface', 'IPs', 'Remote_Interface', 'Remote_IPs']
    )


def func_ip_owners(index, Node, VRF, Interface, IP, Mask, Active):
    return pd.DataFrame(
        index=[index, ],
        data={
            'index': index,
            'Node': Node,
            'VRF': VRF,
            'Interface': Interface,
            'IP': IP,
            'Mask': Mask,
            'Active': Active},
        columns=['index', 'Node', 'VRF', 'Interface', 'IP', 'Mask', 'Active']
    )


for i, bgp_peer in enumerate(config_bgp_peer['Remote_IP']):
    countlist = edges_bgp['Remote_IP'].tolist()
    if (countlist.count(bgp_peer) == 0) and (str(config_bgp_peer.iloc[i, config_bgp_peer.columns.get_loc(
            'Local_AS')]) != str(config_bgp_peer.iloc[i, config_bgp_peer.columns.get_loc('Remote_AS')])):
        config_bgp_proc = config_bgp_proc.append(func_bgp_proc(index=len(config_bgp_proc['Node']),
                                                               Node=str(config_bgp_peer.iloc[i,
                                                                                             config_bgp_peer.columns.get_loc('Remote_AS')]) + '_' + bgp_peer,
                                                               Router_ID=str(config_bgp_peer.iloc[i,
                                                                                                  config_bgp_peer.columns.get_loc('Remote_AS')]) + '_' + bgp_peer,
                                                               Local_AS=str(config_bgp_peer.iloc[i,
                                                                                                 config_bgp_peer.columns.get_loc('Remote_AS')]),
                                                               Local_IP=bgp_peer,
                                                               Remote_AS=str(config_bgp_peer.iloc[i,
                                                                                                  config_bgp_peer.columns.get_loc('Local_AS')]),
                                                               Remote_IP=str(config_bgp_peer.iloc[i,
                                                                                                  config_bgp_peer.columns.get_loc('Local_IP')])),
                                                 ignore_index=True, sort=True)
        edges_bgp = edges_bgp.append(func_edges_bgp(index=len(edges_bgp['Node']),
                                                    Node=str(config_bgp_peer.iloc[i,
                                                                                  config_bgp_peer.columns.get_loc('Node')]),
                                                    Local_AS=str(config_bgp_peer.iloc[i,
                                                                                      config_bgp_peer.columns.get_loc('Local_AS')]),
                                                    Local_IP=str(config_bgp_peer.iloc[i,
                                                                                      config_bgp_peer.columns.get_loc('Local_IP')]),
                                                    Remote_Node=str(config_bgp_peer.iloc[i,
                                                                                         config_bgp_peer.columns.get_loc('Remote_AS')]) + '_' + bgp_peer,
                                                    Remote_AS=str(config_bgp_peer.iloc[i,
                                                                                       config_bgp_peer.columns.get_loc('Remote_AS')]),
                                                    Remote_IP=str(config_bgp_peer.iloc[i,
                                                                                       config_bgp_peer.columns.get_loc('Remote_IP')])), sort=True)

        edges_bgp = edges_bgp.append(func_edges_bgp(index=len(edges_bgp['Node']),
                                                    Node=str(config_bgp_peer.iloc[i,
                                                                                  config_bgp_peer.columns.get_loc('Remote_AS')]) + '_' + bgp_peer,
                                                    Local_AS=str(config_bgp_peer.iloc[i,
                                                                                      config_bgp_peer.columns.get_loc('Remote_AS')]),
                                                    Local_IP=str(config_bgp_peer.iloc[i,
                                                                                      config_bgp_peer.columns.get_loc('Remote_IP')]),
                                                    Remote_Node=str(config_bgp_peer.iloc[i,
                                                                                         config_bgp_peer.columns.get_loc('Node')]),
                                                    Remote_AS=str(config_bgp_peer.iloc[i,
                                                                                       config_bgp_peer.columns.get_loc('Local_AS')]),
                                                    Remote_IP=str(config_bgp_peer.iloc[i,
                                                                                       config_bgp_peer.columns.get_loc('Local_IP')])), sort=True)
        ip_owners = ip_owners.append(func_ip_owners(index=len(ip_owners['IP']),
                                                    Node=str(config_bgp_peer.iloc[i,
                                                                                  config_bgp_peer.columns.get_loc('Remote_AS')]) + '_' + bgp_peer,
                                                    VRF="default",
                                                    Interface=str(config_bgp_peer.iloc[i,
                                                                                config_bgp_peer.columns.get_loc('Remote_IP')]),
                                                    IP=str(config_bgp_peer.iloc[i,
                                                                                config_bgp_peer.columns.get_loc('Remote_IP')]),
                                                    Mask=ip_owners.query('IP == "' + str(config_bgp_peer.iloc[i, config_bgp_peer.columns.get_loc('Local_IP')]) + '"').Mask.values[0],
                                                    Active="True"), sort=True)

        edges_layer3 = edges_layer3.append(func_edges_l3(index=len(edges_layer3['IPs']),
                                                         Node=str(config_bgp_peer.iloc[i,
                                                                                       config_bgp_peer.columns.get_loc('Node')]),
                                                         Interface=ip_owners.query('IP == "' + str(config_bgp_peer.iloc[i,
                                                                                                                        config_bgp_peer.columns.get_loc('Local_IP')]) + '"').Interface.values[0],
                                                         IPs=str(config_bgp_peer.iloc[i,
                                                                                      config_bgp_peer.columns.get_loc('Local_IP')]),
                                                         Remote_Node=ip_owners.query('IP == "' + str(config_bgp_peer.iloc[i,
                                                                                                                          config_bgp_peer.columns.get_loc('Remote_IP')]) + '"').Node.values[0],
                                                         Remote_Interface=str(config_bgp_peer.iloc[i,
                                                                                                   config_bgp_peer.columns.get_loc('Remote_IP')]),
                                                         Remote_IPs=str(config_bgp_peer.iloc[i,
                                                                                             config_bgp_peer.columns.get_loc('Remote_IP')])), sort=True)

        edges_layer3 = edges_layer3.append(func_edges_l3(index=len(edges_layer3['IPs']),
                                                         Node=ip_owners.query('IP == "' + str(config_bgp_peer.iloc[i,
                                                                                                                   config_bgp_peer.columns.get_loc('Remote_IP')]) + '"').Node.values[0],
                                                         Interface=str(config_bgp_peer.iloc[i,
                                                                                            config_bgp_peer.columns.get_loc('Remote_IP')]),
                                                         IPs=str(config_bgp_peer.iloc[i,
                                                                                      config_bgp_peer.columns.get_loc('Remote_IP')]),
                                                         Remote_Node=str(config_bgp_peer.iloc[i,
                                                                                              config_bgp_peer.columns.get_loc('Node')]),
                                                         Remote_Interface=ip_owners.query('IP == "' + str(config_bgp_peer.iloc[i,
                                                                                                                               config_bgp_peer.columns.get_loc('Local_IP')]) + '"').Interface.values[0],
                                                         Remote_IPs=str(config_bgp_peer.iloc[i,
                                                                                             config_bgp_peer.columns.get_loc('Local_IP')])), sort=True)


print(config_bgp_proc)
print(edges_bgp)
print(edges_layer3)
print(ip_owners)
config_bgp_proc.to_csv("config_bgp_proc2.csv")
edges_bgp.to_csv("edges_bgp2.csv")
edges_layer3.to_csv("edges_layer32.csv")
ip_owners.to_csv("ip_owners2.csv")
