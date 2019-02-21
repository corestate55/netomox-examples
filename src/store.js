import Vue from 'vue'
import Vuex from 'vuex'
import { json } from 'd3-request'

Vue.use(Vuex)

export default new Vuex.Store({
  strict: process.env.NODE_ENV !== 'production',
  state: {
    visualizer: 'Dependency',
    modelFile: 'target3b.json',
    wholeLayers: [],
    selectedLayers: [],
    watchInterval: 1000
  },
  mutations: {
    setVisualizer (state, payload) {
      state.visualizer = payload
    },
    setModelFile (state, payload) {
      state.modelFile = payload
    },
    setSelectedLayers (state, payload) {
      state.selectedLayers = payload
    },
    setWholeLayers (state, payload) {
      state.wholeLayers = payload
    },
    setWatchInterval (state, payload) {
      state.watchInterval = payload
    }
  },
  getters: {
    visualizer (state) {
      return state.visualizer
    },
    modelFile (state) {
      return state.modelFile
    },
    selectedLayers (state) {
      return state.selectedLayers
    },
    wholeLayers (state) {
      return state.wholeLayers
    },
    watchInterval (state) {
      return state.watchInterval
    }
  },
  actions: {
    updateModelFile ({ commit, dispatch }, payload) {
      commit('setModelFile', payload)
      dispatch('initializeLayersFromModelFile')
    },
    initializeLayersFromModelFile ({ getters, commit }) {
      const modelFile = getters.modelFile
      json(`/draw/${modelFile}`, (error, modelData) => {
        if (error) {
          throw error
        }
        // graph object data to draw converted from topology json
        const layers = modelData.map(d => d.name)
        commit('setWholeLayers', layers)
        commit('setSelectedLayers', layers)
      })
    }
  }
})
