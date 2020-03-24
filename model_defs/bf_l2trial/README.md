# Batfish trial (L2)

## Reference

local
* [Batfish trial (L3)](../bf_l3trial/README.md)

blog
* [BatfishでL2 Topologyを出せるかどうか調べてみる \- Qiita](https://qiita.com/corestate55/items/50ba0ae3e204d84fb03e)
* [BatfishでL2 Topologyを出せるかどうか調べてみる \(2\) \- Qiita](https://qiita.com/corestate55/items/bfac369b3f4532e5acef)
* [NW機器のコンフィグから力業でL2トポロジを作る \- Qiita](https://qiita.com/corestate55/items/8fa006d1e30f49da36f6)

## Setup

See [Batfish trial (L3)](../bf_l3trial/README.md).
Sample config is at [batfish\-test\-topology](https://github.com/corestate55/batfish-test-topology).
See blogs about these sample configs.

## Convert data from batfish to topology

Exec queries for sample configs and extract results as CSV. 
The script ([exec_queries.py](./exec_queries.py)) exec several queries for each sample3-5 configs.

```
(bf-venv) hagiwara@dev01:~/nwmodel/netomox-examples/model_defs/bf_l2trial$ python exec_queries.py 
```

Convert data (sample3-5).

```
hagiwara@dev01:~/nwmodel/netomox-examples$ for cnt in `seq 3 5`; do bundle exec rake TARGET=./model_defs/bf_l2s${cnt}.rb; done
```

Debug print: use `--debug layer[1-3]` option

```
hagiwara@dev01:~/nwmodel/netomox-examples$ bundle exec ruby ./model_defs/bf_l2s3.rb --debug L1
```
