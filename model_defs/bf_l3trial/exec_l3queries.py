from pybatfish.client.commands import *
from pybatfish.question.question import load_questions
from pybatfish.question import bfq
from os import path, makedirs


def exec_query(snapshot_dir, snapshot_name, csv_dir):
    # load question
    load_questions()
    # init snapshot
    bf_init_snapshot(snapshot_dir, name=snapshot_name, overwrite=True)
    # query
    queries = {
        'ip_owners': lambda: bfq.ipOwners(),
        'routes': lambda: bfq.routes(),
        'edges_bgp': lambda: bfq.edges(edgeType='bgp'),
        'edges_ospf': lambda: bfq.edges(edgeType='ospf'),
        'edges_layer3': lambda: bfq.edges(edgeType='layer3'),
        'config_bgp_proc': lambda: bfq.bgpProcessConfiguration(),
        'config_ospf_area': lambda: bfq.ospfAreaConfiguration(),
        'config_bgp_peer': lambda: bfq.bgpPeerConfiguration(),
    }
    # exec query
    for query in queries:
        print("# Exec Query = %s" % query)
        with open(path.join('', csv_dir, query + '.csv'), 'w') as outfile:
            outfile.write(queries[query]().answer().frame().to_csv())


def dir_info(conf):
    base_dir = path.expanduser(conf['base_dir'])
    return {
        'name': conf['name'],
        'dir': path.join(base_dir, conf['name']),
        'csv_dir': path.join('./csv', conf['name'])
    }


if __name__ == '__main__':
    dir_configs = [
        {
            'name': 'example',
            'base_dir': '~/batfish/pybatfish/jupyter_notebooks/networks'
        },
        {
            'name': 'sample1b',
            'base_dir': '../batfish-test-topology/l3'
        }
    ]
    configs = map(lambda conf: dir_info(conf), dir_configs)
    for config in configs:
        makedirs(config['csv_dir'], exist_ok=True)
        exec_query(config['dir'], config['name'], config['csv_dir'])
