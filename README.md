# netomox-examples

RFC8345-based network topology data and helper tool for its development.

## Project setup (Submodules)

### Initialize submodules

Clone and install submodules at first.

* [batfish-test-topology](https://github.com/corestate55/batfish-test-topology)
  * Sample configs for batfish testing.

```bash
git submodule update --init --recursive
```

### Update submodules

Update submodule repositories. (each submodules uses develop branch as default.)

```bash
git submodule foreach git pull origin develop
```

* Update CSV data files (updating `model_defs/batfish_test_topology`)
  * Exec `python exec_l2queries.py` in `model_defs/bf_l2trial`. See: [Batfish L2 trial doc](model_defs/bf_l2trial/README.md).
  * Exec `bash make_csv.sh` in `model_defs/bf_l3trial`. See: [Batfish L3 trial doc](model_defs/bf_l3trial/README.md)

## Run netoviz (to debug topology of a model)

Run viewer app with its all-in-one container.
(see [netoviz README](https://github.com/corestate55/netoviz) more detail.)

The container settings is in [docker-compose.yml](docker-compose.yml)
* It mounts the `netoviz_model` directory (Rake-tasks outputs model-files (json) into the directory.)

```bash
docker-compose up -d
```

## Project setup (Topology DSL Library)

Install [netomox](https://github.com/corestate55/netomox)
(See [netomox DSL page](https://github.com/corestate55/netomox/blob/develop/dsl.md) about data definition DSL.)

```bash
bundle install --path=vendor/bundle
```

## Edit/Convert model data

### Model data script

Model files are at `./model_defs/`. 
There are several rules for scripts below:

* `./model_defs/foo.rb`
  * requires scripts which defines sub-topology data from under 1-depth subdirectories
    (like `./model_defs/bar/baz.rb`, see [Guardfile](./Guardfile))
  * outputs data to `STDOUT` as JSON data (string).
    It saved as same basename json file in netoviz model directory.
    (`netoviz_model/foo.json`, see [Rakefile](./Rakefile))
  * outputs description string with `-d` option. (It used to index file: rake `make_index` target.)

Additional info:

* [batfish trial (L3)](model_defs/bf_l3trial/README.md): A trial to generate topology data using batfish (for L3 network)
* [batfish trial (L2)](model_defs/bf_l2trial/README.md): A trial for L2 Network

### Topology data generation

Generate (All) topology data files

```bash
bundle exec rake
```

Specify a target file to generate using `TARGET` environment variable.

```bash
bundle exec rake TARGET=./model_defs/hoge.rb
```

### Watch changing script and generate data automatically

It can watch changing files and exec data generate command automatically
when a script edited (saved).

```bash
# watch ./model_defs/foo.rb and files it requires.
bundle exec guard -g ./model_defs/hoge.rb
```

## Edit layout data

`model_defs/layout/foo-layout.json` is layout file of `model_defs/layout/foo.rb`
(it make topology data as `foo.json`).

NOTICE:
* layout files are not watched by `guard` (currently).
* `rake` install corresponding layout file when topology data (json) is generated from model def script.

## Generate Netoviz index

```bash
bundle exec rake make_idnex
```
`make_index` rake task generate index file for netoviz.
(It makes `netoviz/static/model/_index.json` directly.)
If a new model definition script is added in `model_defs/`,
exec `rake make_index` to update netoviz index.
