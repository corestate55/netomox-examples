<template>
  <el-button
    type="success"
    v-on:click="toggleNestReverse"
    v-bind:disabled="visualizerName !== 'Nested'"
    size="small"
    round
  >
    Change Reverse to {{ !nestReverse }}
  </el-button>
</template>

<script>
import { mapGetters, mapActions } from 'vuex'
export default {
  name: 'AppButtonReverseNest.vue',
  computed: {
    ...mapGetters(['visualizerName', 'nestReverse'])
  },
  methods: {
    ...mapActions(['toggleNestReverse'])
  }
}
</script>

<style lang="scss" scoped>
</style>
