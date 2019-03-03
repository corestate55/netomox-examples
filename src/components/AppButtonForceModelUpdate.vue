<template>
  <div>
    <el-button
      type="primary"
      v-on:click="requestUpdate"
    >
      Force Update Model
    </el-button>
  </div>
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
