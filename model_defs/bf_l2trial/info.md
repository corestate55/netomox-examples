# Batfish trial (L2)

## Reference

local
* [Batfish trial (L3)](../bf_l3trial/info.md)

blog
* [BatfishでL2 Topologyを出せるかどうか調べてみる \- Qiita](https://qiita.com/corestate55/items/50ba0ae3e204d84fb03e)
* [BatfishでL2 Topologyを出せるかどうか調べてみる \(2\) \- Qiita](https://qiita.com/corestate55/items/bfac369b3f4532e5acef)

## Setup

### Environment I use

```bash
hagiwara@dev01:~$ lsb_release -a
No LSB modules are available.
Distributor ID: Ubuntu
Description:    Ubuntu 19.10
Release:        19.10
Codename:       eoan
hagiwara@dev01:~$ uname -a
Linux dev01 5.3.0-23-generic #25-Ubuntu SMP Tue Nov 12 09:22:33 UTC 2019 x86_64 x86_64 x86_64 GNU/Linux
hagiwara@dev01:~$ 
```

### Batfish container

Use `docker-compose` to manage batfish container.

```bash
hagiwara@dev01:~/nwmodel/netomox-examples$ docker-compose up -d 
```

### python env and pybatfish

See [Batfish trial (L3)](../bf_l3trial/info.md).
Sample config is at [corestate55/batfish\-l2\-topology\-test](https://github.com/corestate55/batfish-l2-topology-test).
See blogs about these sample configs.

### convert data from batfish to topology

Exec queries for sample configs and extract results as CSV. 
The script ([exec_queries.py](./exec_queries.py)) exec several queries for each sample3-5 configs.
```bash
(bf-venv) hagiwara@dev01:~/nwmodel/netomox-examples/model_defs/bf_l2trial$ python exec_queries.py 
```

Convert data (sample3-5).
```bash
hagiwara@dev01:~/nwmodel/netomox-examples$ for cnt in `seq 3 5`; do bundle exec rake TARGET=./model_defs/bf_l2s${cnt}.rb; done
```

Debug print: use `--debug layer(1-3)` option
```bash
hagiwara@dev01:~/nwmodel/netomox-examples$ bundle exec ruby ./model_defs/bf_l2s3.rb --debug L1
```
