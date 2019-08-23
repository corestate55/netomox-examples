<template>
  <div id="app">
    <el-row>
      <el-col>
        <AppInputParam />
      </el-col>
    </el-row>
    <el-row v-bind:gutter="0">
      <el-col v-bind:span="3">
        <AppButtonForceModelUpdate />
      </el-col>
      <el-col v-bind:span="5">
        <AppInputAlertHost />
      </el-col>
      <el-col v-bind:span="8">
        <AppSelectVisualizer />
      </el-col>
      <el-col v-bind:span="3">
        <AppSwitchReverseNest />
      </el-col>
      <el-col v-bind:span="3">
        <AppInputDepth />
      </el-col>
    </el-row>
    <el-row>
      <VisualizerControl />
    </el-row>
  </div>
</template>

<script>
import AppButtonForceModelUpdate from './components/AppButtonForceModelUpdate'
import AppInputAlertHost from './components/AppInputAlertHost'
import AppSwitchReverseNest from './components/AppSwitchReverseNest'
import AppInputDepth from './components/AppInputDepth'
import AppInputParam from './components/AppInputServerConfig'
import AppSelectVisualizer from './components/AppSelectVisualizer'
import VisualizerControl from './components/VisualizerControl'

export default {
  name: 'app',
  components: {
    AppButtonForceModelUpdate,
    AppInputAlertHost,
    AppSwitchReverseNest,
    AppInputDepth,
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
  .el-row {
    margin: 10pt;
  }
</style>
