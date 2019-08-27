<template>
  <ul>
    <li>
      modelFile: <code>{{ modelFile }}</code>
    </li>
    <li>
      watchInterval: <code>{{ watchInterval }}</code>
    </li>
  </ul>
</template>

<script>
import { mapGetters } from 'vuex'

export default {
  name: 'ListAppConfig',
  computed: {
    ...mapGetters(['modelFile', 'watchInterval'])
  }
}
</script>

<style lang="scss" scoped>
code {
  background-color: lightgoldenrodyellow;
}
</style>
