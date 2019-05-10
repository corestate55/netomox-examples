<template>
  <div id="app">
    <AppButtonForceModelUpdate />
    <AppSelectVisualizer />
    <AppSwitchReverseNest />
    <AppSwitchDeepNest />
    <AppInputParam />
    <VisualizerControl />
  </div>
</template>

<script>
import AppButtonForceModelUpdate from './components/AppButtonForceModelUpdate'
import AppSwitchReverseNest from './components/AppSwitchReverseNest'
import AppSwitchDeepNest from './components/AppSwitchDeepNest'
import AppInputParam from './components/AppInputParam'
import AppSelectVisualizer from './components/AppSelectVisualizer'
import VisualizerControl from './components/VisualizerControl'

export default {
  name: 'app',
  components: {
    AppButtonForceModelUpdate,
    AppSwitchReverseNest,
    AppSwitchDeepNest,
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
