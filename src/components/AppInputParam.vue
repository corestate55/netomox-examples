<template>
  <el-form
    ref="form"
    v-bind:model="form"
    v-bind:inline="true"
  >
    <el-form-item label="Target name">
      <el-input
        v-model="form.target"
        size="small"
      >
        <template slot="append">.json</template>
      </el-input>
    </el-form-item>
    <el-form-item label="Watch interval (msec)">
      <el-input-number
        v-model="form.interval"
        v-bind:step="100"
        v-bind:min="1000"
        size="small"
      />
    </el-form-item>
    <el-form-item>
      <el-button
        type="primary"
        v-on:click="submit"
        size="small"
      >
        Submit
      </el-button>
    </el-form-item>
  </el-form>
</template>

<script>
import { mapGetters, mapMutations, mapActions } from 'vuex'

export default {
  name: 'AppParamInput.vue',
  data () {
    return {
      form: {
        target: '',
        interval: 1000
      }
    }
  },
  mounted () {
    // set initial value from store
    this.form.target = this.getTargetNameFromModelFile()
    this.form.interval = this.watchInterval
  },
  computed: {
    ...mapGetters(['modelFile', 'watchInterval'])
  },
  methods: {
    ...mapMutations(['setWatchInterval']),
    ...mapActions(['updateModelFile']),
    getTargetNameFromModelFile () {
      return this.modelFile.replace(/\.json$/, '')
    },
    submit () {
      this.updateModelFile(this.form.target + '.json')
      this.setWatchInterval(this.form.interval)
      const config = {
        targetName: this.form.target,
        interval: this.form.interval
      }
      fetch('/watcher/config', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json; charset=utf-8'
        },
        body: JSON.stringify(config)
      })
        .then(response => response.text())
        .then(text => {
          console.log('[app param input] submit: ', text)
        })
    }
  }
}
</script>

<style lang="scss" scoped>
.el-input {
  width: 20em;
}
</style>
