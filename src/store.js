import Vue from 'vue'
import Vuex from 'vuex'

Vue.use(Vuex)

export default new Vuex.Store({
  strict: process.env.NODE_ENV !== 'production',
  state: {
    visualizerName: 'Dependency',
    modelFile: 'target3b.json',
    watchInterval: 1000,
    currentAlertRow: { host: '' },
    nestReverse: false,
    nestDepth: 1,
    autoFitting: false
  },
  mutations: {
    setVisualizerName (state, payload) {
      state.visualizerName = payload
    },
    setModelFile (state, payload) {
      state.modelFile = payload
    },
    setWatchInterval (state, payload) {
      state.watchInterval = payload
    },
    setCurrentAlertRow (state, payload) {
      state.currentAlertRow = payload
    },
    setNestReverse (state, payload) {
      state.nestReverse = payload
    },
    setNestDepth (state, payload) {
      state.nestDepth = payload
    },
    setAutoFitting (state, payload) {
      state.autoFitting = payload
    }
  },
  getters: {
    visualizerName (state) {
      return state.visualizerName
    },
    modelFile (state) {
      return state.modelFile
    },
    watchInterval (state) {
      return state.watchInterval
    },
    currentAlertRow (state) {
      return state.currentAlertRow
    },
    nestReverse (state) {
      return state.nestReverse
    },
    nestDepth (state) {
      return state.nestDepth
    },
    autoFitting (state) {
      return state.autoFitting
    }
  }
})
