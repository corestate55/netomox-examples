<template>
  <div id="app">
    <AppButtonForceModelUpdate />
    <AppSelectVisualizer />
    <AppButtonReverseNest />
    <AppInputParam />
    <VisualizerControl />
  </div>
</template>

<script>
import AppButtonForceModelUpdate from './components/AppButtonForceModelUpdate'
import AppButtonReverseNest from './components/AppButtonReverseNest'
import AppInputParam from './components/AppInputParam'
import AppSelectVisualizer from './components/AppSelectVisualizer'
import VisualizerControl from './components/VisualizerControl'

export default {
  name: 'app',
  components: {
    AppButtonForceModelUpdate,
    AppButtonReverseNest,
    AppInputParam,
    AppSelectVisualizer,
    VisualizerControl
  }
}
</script>

<style lang="scss">
#app {
  color: #2c3e50;
  font-size: 11pt;
}
</style>
