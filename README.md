# netomox-examples

RFC8345-based network topology data and helper tool for its development.

## Project setup (Topology DSL Library)
Install [netomox](https://github.com/corestate55/netomox)
```
bundle install path=vendor/bundle
```

Generate (All) topology data files
```
bundle exec rake
```

## Project setup (Helper Viewer)
Install [netoviz](https://github.com/corestate55/netoviz) (as submodule)
```
git submodule update --init --recursive
```
and packages
```
npm install
```

### Run REST API server for development
```
npm run express
```

### Compiles and hot-reloads for development
```
npm run serve
```

### Compiles and minifies for production
```
npm run build
```

### Run your tests
```
npm run test
```

### Lints and fixes files
```
npm run lint
```

### Customize configuration
See [Configuration Reference](https://cli.vuejs.org/config/).
