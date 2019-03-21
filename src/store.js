import Vue from 'vue'
import Vuex from 'vuex'

Vue.use(Vuex)

export default new Vuex.Store({
  strict: process.env.NODE_ENV !== 'production',
  state: {
    visualizerName: 'Dependency',
    modelFile: 'target3b.json',
    watchInterval: 1000,
    nestReverse: false
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
    setNestReverse (state, payload) {
      state.nestReverse = payload
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
    nestReverse (state) {
      return state.nestReverse
    }
  },
  actions: {
    updateModelFile ({ commit }, payload) {
      commit('setModelFile', payload)
    },
    toggleNestReverse ({ state, commit }) {
      commit('setNestReverse', !state.nestReverse)
    }
  }
})
