<template>
  <div id="app">
    <div id="app-debug">
      <ul>
        <li>visualizer: {{ visualizer }}</li>
        <li>modelFile: {{ modelFile }}</li>
      </ul>
    </div>
    <div id="visualizer">
      <!-- entry point -->
    </div>
  </div>
</template>

<script>
import { mapGetters, mapActions } from 'vuex'
import DepGraphVisualizer from '../netoviz/src/dep-graph/visualizer'
import '../netoviz/src/css/dep-graph.scss'

const visualizer = new DepGraphVisualizer()

export default {
  name: 'app',
  methods: {
    ...mapActions(['updateModelFile'])
  },
  computed: {
    ...mapGetters(['visualizer', 'modelFile'])
  },
  mounted () {
    const target = 'target3b.json'
    this.updateModelFile(target)
    visualizer.drawJsonModel(this.modelFile, null)
  }
}
</script>

<style lang="scss">
#app {
  color: #2c3e50;
}
</style>
