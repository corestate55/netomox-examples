<template>
  <div>
    <ul v-if="timestamp">
      <li>Model File: <code>{{ timestamp.modelFile }}</code></li>
      <li>Modified Time (ms): <code>{{ timestamp.mtimeMs }}</code></li>
      <li>Modified Time: <code>{{ timestamp.mtime }}</code></li>
    </ul>
    <div v-if="timestamp && timestamp.makeJsonMessage">
      Message (generate json):
      <pre>{{ timestamp.makeJsonMessage }}</pre>
    </div>
    <div v-if="timestamp && timestamp.verifyJsonMessage">
      Message (verify json):
      <ul>
        <li
          v-for="result in timestamp.verifyJsonMessage"
          v-bind:key="result.checkup"
        >
          {{ result.checkup }}
          <ul v-if="result.messages">
            <!-- TODO: MUST unique v-bind key (only path or message will not unique -->
            <li
              v-for="message in result.messages"
              v-bind:key="message.path + message.message"
            >
              in <code>{{ message.path }}</code> :
              <span v-bind:class="message.severity">
                <strong>[{{ message.severity }}]</strong>
                {{ message.message }}
              </span>
            </li>
          </ul>
        </li>
      </ul>
    </div>
  </div>
</template>

<script>
export default {
  name: 'ListModelFileInfo',
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
.info {
  background-color: #ccff99;
}
.warn {
  background-color: yellow;
}
.error {
  background-color: lightpink;
}
</style>
