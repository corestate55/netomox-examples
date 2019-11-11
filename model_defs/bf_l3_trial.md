# Batfish Trial

## Reference

batfish
* [batfish](https://www.batfish.org/)
* [pybatfish/jupyter\_notebooks/networks at master · batfish/pybatfish · GitHub](https://github.com/batfish/pybatfish/tree/master/jupyter_notebooks/networks)
  * sample configurations

blog
* [Batfish Advent Calendar 2018 \- Qiita](https://qiita.com/advent-calendar/2018/batfish)
  * [BatfishのQuestion一覧と概要説明 - Qiita](https://qiita.com/tech_kitara/items/be71005ad7b5091d25a4)
* [ネットワークコンフィグ検証ツールBatfish使ってみた](https://ccieojisan.net/post-1803/)
* [[Batfish] ネットワーク機器のコンフィグを読み込んでルーティングなどの様々な検証ができるツール「Batfish」の紹介 - てくなべ (tekunabe)](https://tekunabe.hatenablog.jp/entry/2018/10/25/batfish)
* [inet-henge 利用例: Batfish ネットワークトポロジーの可視化 - LGTM](https://codeout.hatenablog.com/)

## Setup

### Environment I use

```bash
hagiwara@dev01:~$ lsb_release -a
No LSB modules are available.
Distributor ID: Ubuntu
Description:    Ubuntu 18.10
Release:        18.10
Codename:       cosmic
hagiwara@dev01:~$ uname -a
Linux dev01 4.18.0-18-generic #19-Ubuntu SMP Tue Apr 2 18:13:16 UTC 2019 x86_64 x86_64 x86_64 GNU/Linux
hagiwara@dev01:~$ 
```

### Batfish container

Install docker at first.

Download and run batfish (all-in-one) container. (tcp/8888 for jupyter notebook if you need.)
```bash
hagiwara@dev01:~$ sudo docker pull batfish/allinone
hagiwara@dev01:~$ sudo docker image ls
REPOSITORY          TAG                 IMAGE ID            CREATED             SIZE
batfish/allinone    latest              7284bc8aa066        9 days ago          957MB
hagiwara@dev01:~$ sudo docker run -p 8888:8888 -p 9997:9997 -p 9996:9996 batfish/allinone
```

### python env and pybatfish
setup venv for python3.
```bash
hagiwara@dev01:~/batfish$ sudo apt install python3-venv
hagiwara@dev01:~/batfish$ python3 -m venv bf-venv
hagiwara@dev01:~/batfish$ . bf-venv/bin/activate
(bf-venv) hagiwara@dev01:~/batfish$ python --version
Python 3.6.8
(bf-venv) hagiwara@dev01:~/batfish$ pip --version
pip 9.0.1 from /home/hagiwara/batfish/bf-venv/lib/python3.6/site-packages (python 3.6)
(bf-venv) hagiwara@dev01:~/batfish$
```

install pybatfish
```bash
(bf-venv) hagiwara@dev01:~/batfish$ pip install wheel
(bf-venv) hagiwara@dev01:~/batfish$ python3 -m pip install --upgrade git+https://github.com/batfish/pybatfish.git                                               
```

### scripts
Setup configs (use [sample config s in batfish](https://github.com/batfish/pybatfish/tree/master/jupyter_notebooks/networks)).
```bash
hagiwara@dev01:~/batfish$ git clone https://github.com/batfish/pybatfish.git
hagiwara@dev01:~/batfish$ ls pybatfish/jupyter_notebooks/networks/example      
configs  example-network.png  hosts  iptables                                  
hagiwara@dev01:~/batfish
```

Exec [bf_make_edge_info_tables.py](./bf_make_edge_info_tables.py) and save data to csv file.
It initialize snapshot for batfish using configurations in `snapshot_dir`.
Then, it throws several queries and save results as csv files.

```bash
(bf-venv) hagiwara@dev01:~/batfish$ python bf_make_edge_info_tables.py
```

## convert data from batfish to topology
Convert data
```bash
hagiwara@dev01:~/nwmodel/netomox-examples/batfish$ bundle exec ruby bf_topology.rb > ../public/model/bf_trial.json
```
For debugging (each layer)
```bash
bundle exec ruby bf_topology.rb [bgp|ospf|l3] 
```

Check data file
```bash
hagiwara@dev01:~/nwmodel/netomox-examples/batfish$ bundle exec netomox check ../public/model/bf_trial.json
```
