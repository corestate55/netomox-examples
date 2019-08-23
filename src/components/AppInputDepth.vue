<template>
  <div id="input-depth">
    <span class="input-label">Depth </span>
    <el-input-number
      v-model="depth"
      controls-position="right"
      v-bind:disabled="visualizerName !== 'Nested'"
      v-on:change="setNestDepth(depth)"
      size="small"
      v-bind:min="1"
      v-bind:max="30"
    />
  </div>
</template>

<script>
import { mapGetters, mapMutations } from 'vuex'
export default {
  name: 'AppInputDeepNest.vue',
  data () {
    return {
      depth: 1
    }
  },
  computed: {
    ...mapGetters(['visualizerName', 'nestDepth'])
  },
  methods: {
    ...mapMutations(['setNestDepth'])
  }
}
</script>

<style scoped lang="scss">
  .input-label {
    display: inline-block;
  }
</style>
