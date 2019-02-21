<template>
<div>
  <div id="visualizer">
    <!-- D3.js entry point -->
  </div>
  <div class="debug">
    <el-collapse>
      <el-collapse-item
        title="App Settings"
        name="appSettings"
      >
        <ul>
          <li>visualizer: {{ visualizer }}</li>
          <li>modelFile: {{ modelFile }}</li>
          <li>watchInterval: {{ watchInterval }}</li>
        </ul>
      </el-collapse-item>
      <el-collapse-item
        title="Timestamps"
        name="timeStamps"
      >
        <ul v-if="currentTimeStamp">
          <li>Model File: {{ currentTimeStamp.modelFile }}</li>
          <li>Modified Time (ms): {{ currentTimeStamp.mtimeMs }}</li>
          <li>Modified Time: {{ currentTimeStamp.mtime }}</li>
          <li>
            Message (generate json):
            <pre>{{ currentTimeStamp.makeJsonMessage }}</pre>
          </li>
          <li>
            Message (verify json):
            <pre>{{ currentTimeStamp.verifyJsonMessage }}</pre>
          </li>
        </ul>
      </el-collapse-item>
    </el-collapse>
  </div>
</div>
</template>

<script>
import { mapGetters } from 'vuex'
import DepGraphVisualizer from '../../netoviz/src/dep-graph/visualizer'
import '../../netoviz/src/css/dep-graph.scss'

const visualizer = new DepGraphVisualizer()

export default {
  name: 'DependencyGraph.vue',
  data () {
    return {
      timer: null,
      currentTimeStamp: null,
      oldTimeStamp: null
    }
  },
  computed: {
    ...mapGetters(['visualizer', 'modelFile', 'watchInterval'])
  },
  methods: {
    setModelUpdateCheckTimer () {
      this.timer = setInterval(async () => {
        try {
          this.oldTimeStamp = this.currentTimeStamp
          this.currentTimeStamp = await this.requestTimeStamp()
        } catch (error) {
          throw error
        }
        if (this.modelUpdated()) {
          console.log('model updated')
          visualizer.drawJsonModel(this.modelFile)
        }
      }, this.watchInterval)
    },
    clearModelUpdateCheckTimer () {
      clearInterval(this.timer)
      this.oldTimeStamp = null
      this.currentTimeStamp = null
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
      return this.oldTimeStamp &&
        this.oldTimeStamp.mtimeMs < this.currentTimeStamp.mtimeMs
    }
  },
  mounted () {
    visualizer.drawJsonModel(this.modelFile)
    this.setModelUpdateCheckTimer()
    this.$store.watch(
      state => state.modelFile,
      (newModelFile, oldModelFile) => {
        visualizer.drawJsonModel(newModelFile)
        this.clearModelUpdateCheckTimer()
        this.setModelUpdateCheckTimer()
      }
    )
  }
}
</script>

<style lang="scss" scoped>
.debug {
  padding: 0.2em;
  border: lightgray solid 1px;
}
</style>
