<template>
  <el-button
    type="warning"
    v-on:click="requestUpdate"
    size="small"
  >
    Force Update
  </el-button>
</template>

<script>
export default {
  name: 'AppButtonForceModelUpdate.vue',
  methods: {
    requestUpdate () {
      fetch('/watcher/force-update', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json; charset=utf-8'
        }
      })
        .then(response => response.text())
        .then(text => {
          console.log('[app model update button] submit: ', text)
        })
    }
  }
}
</script>

<style lang="scss" scoped>
</style>
