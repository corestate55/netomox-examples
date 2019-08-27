<template>
  <div id="input-depth">
    <span class="input-label">Depth </span>
    <el-input-number
      v-model="depth"
      controls-position="right"
      v-bind:disabled="visualizerName !== 'Nested'"
      size="small"
      v-bind:min="1"
      v-bind:max="30"
      v-on:change="setNestDepth(depth)"
    />
  </div>
</template>

<script>
import { mapGetters, mapMutations } from 'vuex'
export default {
  name: 'AppInputDepth',
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
