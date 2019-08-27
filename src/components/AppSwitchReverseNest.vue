<template>
  <el-switch
    v-model="reverse"
    v-bind:disabled="visualizerName !== 'Nested'"
    size="small"
    active-text="Bottom"
    inactive-text="Top"
    inactive-color="#13ce66"
    v-on:change="setNestReverse(reverse)"
  />
</template>

<script>
import { mapGetters, mapMutations } from 'vuex'
export default {
  name: 'AppSwitchReverseNest',
  data () {
    return {
      reverse: false
    }
  },
  computed: {
    ...mapGetters(['visualizerName', 'nestReverse'])
  },
  methods: {
    ...mapMutations(['setNestReverse'])
  }
}
</script>

<style lang="scss" scoped>
</style>
