<template>
  <div id="app">
    <DependencyGraph />
    <AppButtonForceModelUpdate />
    <AppParamInput />
  </div>
</template>

<script>
import AppButtonForceModelUpdate from './components/AppButtonForceModelUpdate'
import AppParamInput from './components/AppParamInput'
import DependencyGraph from './components/DependencyGraph'

export default {
  name: 'app',
  components: {
    AppButtonForceModelUpdate,
    AppParamInput,
    DependencyGraph
  }
}
</script>

<style lang="scss">
#app {
  color: #2c3e50;
}
</style>
