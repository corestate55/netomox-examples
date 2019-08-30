<template>
  <el-switch
    v-model="autoFitting"
    v-bind:disabled="visualizerName !== 'Nested'"
    size="small"
    active-text="Fit Auto"
    inactive-text="Default Layout"
    inactive-color="gray"
  />
</template>

<script>
import { mapGetters } from 'vuex'
export default {
  name: 'AppSwitchFitAuto',
  computed: {
    ...mapGetters(['visualizerName']),
    autoFitting: {
      get () { return this.$store.getters.autoFitting },
      set (value) { this.$store.commit('setAutoFitting', value) }
    }
  }
}
</script>

<style scoped>
</style>
