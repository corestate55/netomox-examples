<template>
  <el-switch
    v-model="reverse"
    v-bind:disabled="visualizerName !== 'Nested'"
    v-on:change="setNestReverse(reverse)"
    size="small"
    active-text="Bottom"
    inactive-text="Top"
  />
</template>

<script>
import { mapGetters, mapMutations } from 'vuex'
export default {
  name: 'AppSwitchReverseNest.vue',
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
