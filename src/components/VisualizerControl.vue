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
import TopoGraphVisualizer from '../../netoviz/src/graph/topology/visualizer'
import DepGraphVisualizer from '../../netoviz/src/graph/dependency/visualizer'
import Dep2GraphVisualizer from '../../netoviz/src/graph/dependency2/visualizer'
import NestedGraphVisualizer from '../../netoviz/src/graph/nested/visualizer'
// import '../../netoviz/src/css/topology.scss' // TODO: not work, use alternative scss
import '../css/topo-graph.scss' // alternative
import '../../netoviz/src/css/dependency.scss'
import '../../netoviz/src/css/nested.scss'
import '../css/dep-graph.scss'
import '../../netoviz/src/css/tooltip.scss'

export default {
  name: 'VisualizerControl',
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
      unwatchGraphParam: null,
      timer: null,
      currentTimestampInfo: null,
      oldTimestampInfo: null
    }
  },
  computed: {
    ...mapGetters(
      ['visualizerName', 'modelFile', 'watchInterval', 'currentAlertRow', 'nestReverse', 'nestDepth']
    )
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
    this.unwatchGraphParam = this.$store.watch(
      state => [state.currentAlertRow.host, state.nestReverse, state.nestDepth].join(', '),
      (newNestParam) => {
        console.log(`change graph params to: ${newNestParam}`)
        this.drawJsonModel()
      }
    )
  },
  beforeDestroy () {
    delete this.visualizer
    this.unwatchModelFile()
    this.unwatchVisualizerName()
    this.unwatchGraphParam()
  },
  methods: {
    setModelUpdateCheckTimer () {
      this.timer = setInterval(async () => {
        this.oldTimestampInfo = this.currentTimestampInfo
        this.currentTimestampInfo = await this.requestTimeStamp()
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
      const response = await fetch('/watcher/timestamp')
      return response.json()
    },
    modelUpdated () {
      return this.oldTimestampInfo &&
        this.oldTimestampInfo.mtimeMs < this.currentTimestampInfo.mtimeMs
    },
    drawJsonModel () {
      this.visualizer.drawJsonModel(
        this.modelFile, this.currentAlertRow, this.nestReverse, this.nestDepth
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
      const svgWidth = window.innerWidth * 0.95
      const svgHeight = window.innerHeight * 0.8
      if (visualizerName === 'Topology') {
        this.visualizer = new TopoGraphVisualizer()
      } else if (visualizerName === 'Nested') {
        this.visualizer = new NestedGraphVisualizer(svgWidth, svgHeight)
      } else if (visualizerName === 'Dependency2') {
        this.visualizer = new Dep2GraphVisualizer(svgWidth, svgHeight)
      } else {
        // default: dependency graph
        this.visualizer = new DepGraphVisualizer(svgWidth, svgHeight)
      }
      this.resetGraph()
    }
  }
}
</script>

<style lang="scss" scoped>
</style>
