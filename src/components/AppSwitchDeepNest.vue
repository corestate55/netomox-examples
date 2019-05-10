<template>
  <el-switch
    v-model="deep"
    v-bind:disabled="visualizerName !== 'Nested'"
    v-on:change="setNestDeep(deep)"
    size="small"
    active-text="Deep"
    inactive-text="Shallow"
  />
</template>

<script>
import { mapGetters, mapMutations } from 'vuex'
export default {
  name: 'AppSwitchDeepNest.vue',
  data () {
    return {
      deep: false
    }
  },
  computed: {
    ...mapGetters(['visualizerName', 'nestDeep'])
  },
  methods: {
    ...mapMutations(['setNestDeep'])
  }
}
</script>

<style scoped>

</style>
