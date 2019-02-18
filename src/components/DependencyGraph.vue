<template>
<div>
  <div id="app-debug">
    <ul>
      <li>visualizer: {{ visualizer }}</li>
      <li>modelFile: {{ modelFile }}</li>
    </ul>
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
  computed: {
    ...mapGetters(['visualizer', 'modelFile'])
  },
  methods: {
    ...mapActions(['updateModelFile'])
  },
  mounted () {
    const target = 'target3b.json'
    this.updateModelFile(target)
    visualizer.drawJsonModel(this.modelFile, null)
  }
}
</script>

<style lang="scss" scoped>
</style>
