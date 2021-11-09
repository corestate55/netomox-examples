from pybatfish.client.commands import *
from pybatfish.question.question import load_questions
from pybatfish.question import bfq
from os import path, makedirs


def exec_query(snapshot_dir, snapshot_name, csv_dir):
    # load question
    load_questions()
    # init snapshot
    bf_init_snapshot(snapshot_dir, name=snapshot_name)
    # query
    queries = {
        'ip_owners': lambda: bfq.ipOwners(),
        'edges_layer1': lambda: bfq.edges(edgeType='layer1'),
        'edges_layer3': lambda: bfq.edges(edgeType='layer3'),
        'interface_props': lambda: bfq.interfaceProperties(nodes='.*', properties='.*'),
        'node_props': lambda: bfq.nodeProperties(nodes='.*', properties='Configuration_Format, VRFs, Interfaces'),
        'sw_vlan_props': lambda: bfq.switchedVlanProperties(nodes='.*')
    }
    # exec query
    for query in queries:
        print("# Exec Query = %s" % query)
        with open(path.join(csv_dir, query + '.csv'), 'w') as outfile:
            outfile.write(queries[query]().answer().frame().to_csv())


def dir_info(name):
    base_dir = path.expanduser('../batfish-test-topology/l2')
    return {
        'name': name,
        'dir': path.join(base_dir, name),
        'csv_dir': path.join('./csv', name)
    }


if __name__ == '__main__':
    dirs = map(lambda d: dir_info(d), ['sample3']) # ['sample3', 'sample4', 'sample5']
    for d in dirs:
        makedirs(d['csv_dir'], exist_ok=True)
        exec_query(d['dir'], d['name'], d['csv_dir'])
