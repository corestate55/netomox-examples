<template>
<div>
  <div id="visualizer">
    <!-- D3.js entry point -->
  </div>
  <div class="debug">
    <div>
      app setting:
      <ul>
        <li>visualizer: {{ visualizer }}</li>
        <li>modelFile: {{ modelFile }}</li>
      </ul>
    </div>
    <div v-if="currentTimeStamp">
      timestamps:
      <ul>
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
    </div>
  </div>
</div>
</template>

<script>
import { mapGetters, mapActions } from 'vuex'
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
    ...mapGetters(['visualizer', 'modelFile'])
  },
  methods: {
    ...mapActions(['updateModelFile']),
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
      }, 1500) // TODO: set interval
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
    const target = 'target3b.json' // TODO: model select, POST config server
    this.updateModelFile(target)
    visualizer.drawJsonModel(this.modelFile)
    this.setModelUpdateCheckTimer()
  }
}
</script>

<style lang="scss" scoped>
.debug {
  background-color: lightgray;
  padding: 1em;
}
</style>
