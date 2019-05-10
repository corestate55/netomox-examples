<template>
<div>
  <div id="visualizer">
    <!-- D3.js entry point -->
  </div>
  <div class="debug">
    <el-tabs type="border-card">
      <el-tab-pane label="App Configs">
        <ListAppConfig />
      </el-tab-pane>
      <el-tab-pane label="Server Configs">
        <ListWatchConfig />
      </el-tab-pane>
      <el-tab-pane label="Model File Info">
        <ListModelFileInfo
          v-bind:timestamp="currentTimestampInfo"
        />
      </el-tab-pane>
    </el-tabs>
  </div>
</div>
</template>

<script>
import { mapGetters } from 'vuex'
import ListAppConfig from './ListAppConfig'
import ListModelFileInfo from './ListModelFileInfo'
import ListWatchConfig from './ListWatcherConfig'
import DepGraphVisualizer from '../../netoviz/src/graph/dependency/visualizer'
import NestedGraphVisualizer from '../../netoviz/src/graph/nested/visualizer'
import '../../netoviz/src/css/dependency.scss'
import '../../netoviz/src/css/nested.scss'
import '../../netoviz/src/css/tooltip.scss'
import '../css/dep-graph.scss'

export default {
  name: 'VisualizerControl.vue',
  components: {
    ListAppConfig,
    ListModelFileInfo,
    ListWatchConfig
  },
  data () {
    return {
      visualizer: null,
      unwatchModelFile: null,
      unwatchVisualizerName: null,
      unwatchNestParam: null,
      timer: null,
      currentTimestampInfo: null,
      oldTimestampInfo: null
    }
  },
  computed: {
    ...mapGetters(
      ['visualizerName', 'modelFile', 'watchInterval', 'nestReverse', 'nestDeep']
    )
  },
  methods: {
    setModelUpdateCheckTimer () {
      this.timer = setInterval(async () => {
        try {
          this.oldTimestampInfo = this.currentTimestampInfo
          this.currentTimestampInfo = await this.requestTimeStamp()
        } catch (error) {
          throw error
        }
        if (this.modelUpdated()) {
          console.log('model updated')
          this.drawJsonModel()
        }
      }, this.watchInterval)
    },
    clearModelUpdateCheckTimer () {
      clearInterval(this.timer)
      this.oldTimestampInfo = null
      this.currentTimestampInfo = null
      this.timer = null
    },
    async requestTimeStamp () {
      try {
        const response = await fetch('/watcher/timestamp')
        return await response.json()
      } catch (error) {
        throw error
      }
    },
    modelUpdated () {
      return this.oldTimestampInfo &&
        this.oldTimestampInfo.mtimeMs < this.currentTimestampInfo.mtimeMs
    },
    drawJsonModel () {
      this.visualizer.drawJsonModel(
        this.modelFile, null, this.nestReverse, this.nestDeep
      )
    },
    resetGraph () {
      this.drawJsonModel()
      this.clearModelUpdateCheckTimer()
      this.setModelUpdateCheckTimer()
    },
    resetVisualizer (visualizerName) {
      console.log(`[viz] visualizerName: ${visualizerName}`)
      delete this.visualizer
      if (visualizerName === 'Nested') {
        this.visualizer = new NestedGraphVisualizer()
      } else {
        // default: dependency graph
        this.visualizer = new DepGraphVisualizer()
      }
      this.resetGraph()
    }
  },
  mounted () {
    this.resetVisualizer(this.visualizerName)
    this.unwatchModelFile = this.$store.watch(
      state => state.modelFile,
      (newModelFile) => { this.resetGraph() }
    )
    this.unwatchVisualizerName = this.$store.watch(
      state => state.visualizerName,
      (newVisualizerName) => {
        console.log(`change visualizer to: ${newVisualizerName}`)
        this.resetVisualizer(newVisualizerName)
      }
    )
    this.unwatchNestParam = this.$store.watch(
      state => state.nestReverse + state.nestDeep,
      (newNestParam) => { this.drawJsonModel() }
    )
  },
  beforeDestroy () {
    delete this.visualizer
    this.unwatchModelFile()
    this.unwatchVisualizerName()
    this.unwatchNestParam()
  }
}
</script>

<style lang="scss" scoped>
</style>
