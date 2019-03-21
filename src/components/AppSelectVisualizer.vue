<template>
  <el-radio-group
    v-model="visualizerName"
    size="small"
  >
    <el-radio-button label="Dependency" />
    <el-radio-button label="Nested" />
  </el-radio-group>
</template>

<script>
export default {
  name: 'AppSelectVisualizer.vue',
  computed: {
    visualizerName: {
      get () { return this.$store.getters.visualizerName },
      set (value) { this.$store.commit('setVisualizerName', value) }
    }
  }
}
</script>

<style lang="scss" scoped>
</style>
