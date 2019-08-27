<template>
  <ul>
    <li
      v-for="(value, key) in config"
      v-bind:key="key"
    >
      {{ key }} :
      <ul v-if="Object.prototype.toString.call(value) === '[object Array]'">
        <li
          v-for="item in value"
          v-bind:key="item"
        >
          <code>{{ item }}</code>
        </li>
      </ul>
      <code v-else>{{ value }}</code>
    </li>
  </ul>
</template>

<script>
export default {
  name: 'ListWatcherConfig',
  data () {
    return {
      config: null,
      unwatchAppSettings: null
    }
  },
  created () {
    this.updateConfig()
  },
  mounted () {
    this.unwatchAppSettings = this.$store.watch(
      state => `${state.modelFile}/${state.watchInterval}`,
      () => { this.updateConfig() }
    )
  },
  beforeDestroy () {
    this.unwatchAppSettings()
  },
  methods: {
    async updateConfig () {
      const response = await fetch('/watcher/config')
      this.config = await response.json()
    }
  }
}
</script>

<style lang="scss" scoped>
code {
  background-color: lightgoldenrodyellow;
}
</style>
