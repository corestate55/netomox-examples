import Vue from 'vue'
import Vuex from 'vuex'

Vue.use(Vuex)

export default new Vuex.Store({
  strict: process.env.NODE_ENV !== 'production',
  state: {
    visualizerName: 'Dependency',
    modelFile: 'target3b.json',
    watchInterval: 1000
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
    }
  },
  actions: {
    updateModelFile ({ commit, dispatch }, payload) {
      commit('setModelFile', payload)
    }
  }
})
