<template>
  <div id="app">
    <DependencyGraph />
  </div>
</template>

<script>
import DependencyGraph from './components/DependencyGraph'
export default {
  name: 'app',
  components: {
    DependencyGraph
  }
}
</script>

<style lang="scss">
#app {
  color: #2c3e50;
}
</style>
