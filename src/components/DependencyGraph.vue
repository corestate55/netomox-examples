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
      <el-tab-pane label="Timestamps">
        <ListModelFileInfo
          v-bind:timestamp="currentTimestampInfo"
        />
      </el-tab-pane>
      <el-tab-pane label="Server Configs">
        <ListWatchConfig />
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
import DepGraphVisualizer from '../../netoviz/src/dep-graph/visualizer'
import '../../netoviz/src/css/dep-graph.scss'
import '../css/dep-graph.scss'

export default {
  name: 'DependencyGraph.vue',
  components: {
    ListAppConfig,
    ListModelFileInfo,
    ListWatchConfig
  },
  data () {
    return {
      visualizer: null,
      unwatchModelFile: null,
      timer: null,
      currentTimestampInfo: null,
      oldTimestampInfo: null
    }
  },
  computed: {
    ...mapGetters(['modelFile', 'watchInterval'])
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
          this.visualizer.drawJsonModel(this.modelFile)
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
    resetGraph () {
      this.visualizer.drawJsonModel(this.modelFile)
      this.clearModelUpdateCheckTimer()
      this.setModelUpdateCheckTimer()
    }
  },
  mounted () {
    this.visualizer = new DepGraphVisualizer()
    this.resetGraph()
    this.unwatchModelFile = this.$store.watch(
      state => state.modelFile,
      (newModelFile) => { this.resetGraph() }
    )
  },
  beforeDestroy () {
    delete this.visualizer
    this.unwatchModelFile()
  }
}
</script>

<style lang="scss" scoped>
</style>
