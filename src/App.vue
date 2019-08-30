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
      <el-col v-bind:span="10">
        <AppSelectVisualizer />
      </el-col>
    </el-row>
    <!-- control for nested view -->
    <el-row>
      <el-col v-bind:span="3">
        <span>Control for Nested</span>
      </el-col>
      <el-col v-bind:span="3">
        <AppSwitchReverseNest />
      </el-col>
      <el-col v-bind:span="5">
        <AppSwitchFitAuto />
      </el-col>
      <el-col v-bind:span="5">
        <AppInputDepth />
      </el-col>
    </el-row>
    <!-- selected diagram view -->
    <el-row>
      <VisualizerControl />
    </el-row>
  </div>
</template>

<script>
import AppButtonForceModelUpdate from './components/AppButtonForceModelUpdate'
import AppInputAlertHost from './components/AppInputAlertHost'
import AppInputDepth from './components/AppInputDepth'
import AppSwitchReverseNest from './components/AppSwitchReverseNest'
import AppSwitchFitAuto from './components/AppSwitchFitAuto'
import AppInputParam from './components/AppInputServerConfig'
import AppSelectVisualizer from './components/AppSelectVisualizer'
import VisualizerControl from './components/VisualizerControl'

export default {
  name: 'App',
  components: {
    AppButtonForceModelUpdate,
    AppInputAlertHost,
    AppInputDepth,
    AppInputParam,
    AppSwitchReverseNest,
    AppSwitchFitAuto,
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
