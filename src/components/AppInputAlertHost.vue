<template>
  <div id="alert-host">
    <span class="input-label">Alert Host </span>
    <el-input
      v-model="alertHost"
      class="host-input"
      sizer="small"
      v-on:change="setCurrentAlertRow({ 'host': alertHost })"
    />
  </div>
</template>

<script>
import { mapGetters, mapMutations } from 'vuex'
export default {
  name: 'AppInputAlertHost',
  data () {
    return {
      alertHost: ''
    }
  },
  computed: {
    ...mapGetters(['currentAlertRow'])
  },
  methods: {
    ...mapMutations(['setCurrentAlertRow'])
  }
}
</script>

<style scoped lang="scss">
  .host-input {
    width: 200px;
  }
  .input-label {
    display: inline-block;
    width: 30%;
  }
</style>
