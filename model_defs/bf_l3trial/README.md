# Batfish Trial (L3)

## About

Target of batfish L3 trial is construct network-system model and draw as diagram from network device configurations using batfish.
This scripts creates network layers about layer3 and routing protocols relations.

* Layer3 topology
* OSPF Area and Process topology
* BGP AS and Process topology

Results (pybatfish example):
* [Batfish を使ってネットワーク構成を可視化してみよう \(1\) \- Qiita](https://qiita.com/corestate55/items/8a39af553785fd77c20a)
* [Batfish を使ってネットワーク構成を可視化してみよう \(2\) \- Qiita](https://qiita.com/corestate55/items/9d8023eb19637f9bbd1e)
* [Batfish を使ってネットワーク構成を可視化してみよう \(3\) \- Qiita](https://qiita.com/corestate55/items/10673ef74c33a24a0389)

Results (sample1):
* TBA

About batfish:
* [batfish](https://www.batfish.org/)
* [pybatfish/jupyter\_notebooks/networks at master · batfish/pybatfish · GitHub](https://github.com/batfish/pybatfish/tree/master/jupyter_notebooks/networks)
  * sample configurations used here.
* [Batfish Advent Calendar 2018 \- Qiita](https://qiita.com/advent-calendar/2018/batfish)
  * [BatfishのQuestion一覧と概要説明 - Qiita](https://qiita.com/tech_kitara/items/be71005ad7b5091d25a4)
* [ネットワークコンフィグ検証ツールBatfish使ってみた](https://ccieojisan.net/post-1803/)
* [[Batfish] ネットワーク機器のコンフィグを読み込んでルーティングなどの様々な検証ができるツール「Batfish」の紹介 - てくなべ (tekunabe)](https://tekunabe.hatenablog.jp/entry/2018/10/25/batfish)
* [inet-henge 利用例: Batfish ネットワークトポロジーの可視化 - LGTM](https://codeout.hatenablog.com/)

## Setup

### Trial environment

2020-Mar

```
hagiwara@dev01:~/nwmodel/netomox-examples$ lsb_release -a
No LSB modules are available.
Distributor ID: Ubuntu
Description:    Ubuntu 19.10
Release:        19.10
Codename:       eoan
hagiwara@dev01:~/nwmodel/netomox-examples$ uname -a
Linux dev01 5.3.0-42-generic #34-Ubuntu SMP Fri Feb 28 05:49:40 UTC 2020 x86_64 x86_64 x86_64 GNU/Linux
hagiwara@dev01:~/nwmodel/netomox-examples$ 
```

### Clone sample configs (pybatfish example)

Setup configs (use [sample config s in batfish](https://github.com/batfish/pybatfish/tree/master/jupyter_notebooks/networks)).

```
hagiwara@dev01:~/batfish$ git clone https://github.com/batfish/pybatfish.git
hagiwara@dev01:~/batfish$ ls pybatfish/jupyter_notebooks/networks/example      
configs  example-network.png  hosts  iptables                                  
hagiwara@dev01:~/batfish
```

### Clone sample configs (batfish l3-trial)

Clone it as submodule. See: [README.md](../../README.md)

* samples repository: [batfish\-test\-topology](https://github.com/corestate55/batfish-test-topology)
* There are two variations in sample1:
  * sample1a: includes configurations of external AS. (for constructing configs in GNS3)
  * sample1b: does not includes external AS configs. (for this trial.)
    Usually, AS admins can not know about details of external AS configurations except of bgp-peer parameters.
    So, bf_l3trial scripts complement external AS information from peer parameters.

```
hagiwara@dev01:~/nwmodel/netomox-examples/model_defs/batfish-test-topology$ ls
README.md  docker-compose.yml  l2  l3  setup_bfq.py
hagiwara@dev01:~/nwmodel/netomox-examples/model_defs/batfish-test-topology$ 
```

### Run batfish container

Install docker at first.

Download and run batfish (all-in-one) container. (tcp/8888 for jupyter notebook if you need.)

```
hagiwara@dev01:~$ sudo docker pull batfish/allinone
hagiwara@dev01:~$ docker image ls
REPOSITORY          TAG                 IMAGE ID            CREATED             SIZE
batfish/allinone    latest              4687b954c765        3 weeks ago         1.02GB
hagiwara@dev01:~$ docker run -p 8888:8888 -p 9997:9997 -p 9996:9996 batfish/allinone
```

OR able to use docker-compose using `docker-compose.yml` in cloned sample config repository.

```
hagiwara@dev01:~/nwmodel/netomox-examples/model_defs/batfish-test-topology$ docker-compose up -d
```
Then, batfish container is running.

```
hagiwara@dev01:~$ docker ps
CONTAINER ID        IMAGE               COMMAND             CREATED             STATUS              PORTS                                        NAMES
5af6abe4aba6        batfish/allinone    "./wrapper.sh"      7 hours ago         Up 2 hours
          8888/tcp, 0.0.0.0:9996-9997->9996-9997/tcp   batfish
hagiwara@dev01:~$ 
```

Next, send queries to batfish using pybatfish, and save the results.

### Setup python env and pybatfish

[Pybatfish](https://github.com/batfish/pybatfish) is a python frontend for batfish.
Setup venv for python3 before install pybatfish.

```
hagiwara@dev01:~/batfish$ sudo apt install python3-venv
hagiwara@dev01:~/batfish$ python3 -m venv bf-venv
hagiwara@dev01:~/batfish$ . bf-venv/bin/activate
(bf-venv) hagiwara@dev01:~/batfish/batfish-test-topology$ python --version
Python 3.7.5
(bf-venv) hagiwara@dev01:~/batfish/batfish-test-topology$ pip --version
pip 20.0.2 from /home/hagiwara/batfish/bf-venv/lib/python3.7/site-packages/pip (python 3.7)
(bf-venv) hagiwara@dev01:~/batfish/batfish-test-topology$ 
```

Install pybatfish (See: [pybatfish on github](https://github.com/batfish/pybatfish#install-pybatfish))

```
(bf-venv) hagiwara@dev01:~/batfish$ pip install wheel
(bf-venv) hagiwara@dev01:~/batfish$ python3 -m pip install --upgrade git+https://github.com/batfish/pybatfish.git
```

### Generate data from router configurations using batfish.

Exec batfish queries and save its answers as csv files. (exec once when config files are updated.)

* `make_csv.sh` backups original batfish answers as `.orig.csv`
  and add complemented bgp peer information into each CSVs.
  * With `-c` option: it removes (cleans) these backup files.

```
hagiwara@dev01:~/nwmodel/netomox-examples/model_defs/bf_l3trial$ ./make_csv.sh -c
```

`make_csv.sh` kicks two python scripts:

* `exec_l3queries.py`: Send queries to batfish and save its answers as csv files.
* `ebgp_peer_data.py` : Complement the router (eBGP-peer) information of the external AS
  that does not exist as a configuration.


## Convert query answers to topology data

Convert batfish query answers to RFC8345 topology data:

* `bf_l3ex.rb`: for pybatfish-example topology.
* `bf_l3s1.rb`: for l3trial sample1 topology.

```
hagiwara@dev01:~/nwmodel/netomox-examples$ bundle exec rake TARGET=./model_defs/bf_l3ex.rb
hagiwara@dev01:~/nwmodel/netomox-examples$ bundle exec rake TARGET=./model_defs/bf_l3s1.rb
```

For debugging (each layer)

```
# ruby model_defs/bf_l3ex.rb --debug=[bgp_as|bgp_proc|ospf_area|ospf_proc|l3]
hagiwara@dev01:~/nwmodel/netomox-examples$ bundle exec ruby model_defs/bf_l3ex.rb --debug=bgp_as
```

Check data file

```
hagiwara@dev01:~/nwmodel/netomox-examples$ bundle exec netomox check netoviz/static/model/bf_l3ex.json
hagiwara@dev01:~/nwmodel/netomox-examples$ bundle exec netomox check netoviz/static/model/bf_l3s1.json
```
