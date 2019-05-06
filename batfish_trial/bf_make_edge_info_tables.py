from pybatfish.client.commands import *
from pybatfish.question.question import load_questions
from pybatfish.question import bfq

snapshot_dir = 'pybatfish/jupyter_notebooks/networks/example'
snapshot_name = 'bf_example_snapshot'

if __name__ == '__main__':
    # load question
    load_questions()
    # init snapshot
    bf_init_snapshot(snapshot_dir, name=snapshot_name)
    # query
    queries = {
        'ip_owners': lambda: bfq.ipOwners(),
        'edges_bgp': lambda: bfq.edges(edgeType='bgp'),
        'edges_ospf': lambda: bfq.edges(edgeType='ospf'),
        'edges_layer3': lambda: bfq.edges(edgeType='layer3'),
        'config_bgp_proc': lambda: bfq.bgpProcessConfiguration(),
        'config_ospf_area': lambda: bfq.ospfAreaConfiguration(),
    }
    # exec query
    for query in queries:
        print("# Exec Query = %s" % query)
        with open(query + '.csv', 'w') as outfile:
            outfile.write(queries[query]().answer().frame().to_csv())
