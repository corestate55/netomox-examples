<template>
  <div id="app">
    <DependencyGraph />
    <AppParamInput />
  </div>
</template>

<script>
import AppParamInput from './components/AppParamInput'
import DependencyGraph from './components/DependencyGraph'
export default {
  name: 'app',
  components: {
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
