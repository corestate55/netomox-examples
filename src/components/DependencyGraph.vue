<template>
<div>
  <div class="debug">
    <div>
      app setting:
      <ul>
        <li>visualizer: {{ visualizer }}</li>
        <li>modelFile: {{ modelFile }}</li>
      </ul>
    </div>
    <div v-show="currentTimeStamp">
      timestamps:
      <ul>
        <li
          v-for="(value, key) in currentTimeStamp"
          v-bind:key="key"
        >
          {{ key }} : {{ value }}
        </li>
      </ul>
    </div>
  </div>
  <div id="visualizer">
    <!-- D3.js entry point -->
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
      this.timer = setInterval(() => {
        this.updateTimeStamp()
        if (this.modelUpdated()) {
          visualizer.drawJsonModel(this.modelFile)
        }
      }, 1500) // TODO: set interval
    },
    async updateTimeStamp () {
      this.oldTimeStamp = this.currentTimeStamp
      try {
        const response = await fetch('/watcher/timestamp')
        this.currentTimeStamp = await response.json()
      } catch (error) {
        console.error('fetch timestamp failed', error)
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
