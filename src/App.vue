<template>
  <div id="app">
    <DependencyGraph />
    <AppButtonForceModelUpdate />
    <AppInputParam />
  </div>
</template>

<script>
import AppButtonForceModelUpdate from './components/AppButtonForceModelUpdate'
import AppInputParam from './components/AppInputParam'
import DependencyGraph from './components/DependencyGraph'

export default {
  name: 'app',
  components: {
    AppButtonForceModelUpdate,
    AppInputParam,
    DependencyGraph
  }
}
</script>

<style lang="scss">
#app {
  color: #2c3e50;
  font-size: 11pt;
}
</style>
