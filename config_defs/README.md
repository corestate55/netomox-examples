# "Model to Config" trial

## Generate network config from topology data

Generate network config for tinet from layer3 topology data.

See also:
* [tinynetwork/tinet: TiNET](https://github.com/tinynetwork/tinet)
* [Dockerで始めるネットワーク実験入門 2020-5-30 C-4 - YouTube](https://youtu.be/_gaeI56vmPI)

### Target topology data

Target: `netoviz/static/model/bf_l3s1.json`

The topology data is converted from router configs.
See [Batfish Trial (L3)](../model_defs/bf_l3trial/README.md) to generate it.

### Convert topology data

Run model converter
```
hagiwara@dev02:~/nwmodel/netomox-examples$ bundle exec ruby config_defs/topo2config_converter.rb
```

Then, it output yaml files for tinet.
Check and save it as `spec.yaml` for tinet.
```
hagiwara@dev02:~/nwmodel/netomox-examples$ bundle exec ruby config_defs/topo2config_converter.rb | config_defs/spec.yaml
```

### Setup network with tinet

Run `tinet upconf` without shell pipeline to check commands.
```
hagiwara@dev02:~/nwmodel/netomox-examples$ cd config_defs
hagiwara@dev02:~/nwmodel/netomox-examples/config_defs$ tinet upconf -c spec.yaml
```

Run `tinet up` and `conf` (or `upconf`) to construct network.
```
hagiwara@dev02:~/nwmodel/netomox-examples/config_defs$ tinet up -c spec.yaml | sudo sh -x
hagiwara@dev02:~/nwmodel/netomox-examples/config_defs$ tinet conf -c spec.yaml | sudo sh -x
```

List booted containers
```
hagiwara@dev02:~/nwmodel/netomox-examples$ docker ps
CONTAINER ID        IMAGE               COMMAND             CREATED             STATUS              PORTS               NAMES
e1e3f90ca738        slankdev/frr        "/bin/bash"         21 minutes ago      Up 21 minutes                           core02
0d18fd4b06cd        slankdev/frr        "/bin/bash"         21 minutes ago      Up 21 minutes                           core01
e10295be9984        slankdev/frr        "/bin/bash"         21 minutes ago      Up 21 minutes                           border21
e74376d93f42        slankdev/frr        "/bin/bash"         21 minutes ago      Up 21 minutes                           border12
c61140b36ede        slankdev/frr        "/bin/bash"         21 minutes ago      Up 21 minutes                           border11
49800f759562        slankdev/frr        "/bin/bash"         21 minutes ago      Up 21 minutes                           border01
f6748fe73705        slankdev/frr        "/bin/bash"         21 minutes ago      Up 21 minutes                           as65534_10.0.1.13
c56a96bebdf1        slankdev/frr        "/bin/bash"         21 minutes ago      Up 21 minutes                           as65534_10.0.0.45
d80e50c5e94f        slankdev/frr        "/bin/bash"         21 minutes ago      Up 21 minutes                           as65533_10.0.0.17
hagiwara@dev02:~/nwmodel/netomox-examples$
```

Run shell into a container. (exec `bash` or `vtysh`)
```
hagiwara@dev02:~/nwmodel/netomox-examples$ docker exec -it border01 bash
root@border01:/#
```

Run `tinet test` to test p2p link ping.
```
hagiwara@dev02:~/nwmodel/netomox-examples/config_defs$ tinet test -c spec.yaml | sudo sh -x
```

Run `tinet down` to clear network.
```
hagiwara@dev02:~/nwmodel/netomox-examples/config_defs$ tinet down -c spec.yaml | sudo sh -x
```
