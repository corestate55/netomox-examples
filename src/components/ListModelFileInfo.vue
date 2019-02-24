<template>
  <ul v-if="timestamp">
    <li>Model File: <code>{{ timestamp.modelFile }}</code></li>
    <li>Modified Time (ms): <code>{{ timestamp.mtimeMs }}</code></li>
    <li>Modified Time: <code>{{ timestamp.mtime }}</code></li>
    <li>
      Message (generate json):
      <pre>{{ timestamp.makeJsonMessage }}</pre>
    </li>
    <li>
      Message (verify json):
      <pre>{{ timestamp.verifyJsonMessage }}</pre>
    </li>
  </ul>
</template>

<script>
export default {
  name: 'ListModelFileInfo.vue',
  props: {
    timestamp: {
      type: Object,
      default: () => {}
    }
  }
}
</script>

<style lang="scss" scoped>
code, pre {
  background-color: lightgoldenrodyellow;
}
</style>
