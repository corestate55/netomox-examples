import express from 'express';
import TopologyDataAPI from '../netoviz/srv/topology-data-api'

const port = process.env.PORT || 3000 // process.env.PORT for Heroku
const topoDataAPI = new TopologyDataAPI(process.env.NODE_ENV)

export default (app, http) => {
  app.use(express.json())
  app.set('port', port)

  app.get('/draw/:jsonName', (req, res) => {
    res.type('json')
    res.send(topoDataAPI.convertTopoGraphData(req))
  })
  app.get('/draw-dep-graph/:jsonName', (req, res) => {
    res.type('json')
    res.send(topoDataAPI.convertDependencyGraphData(req))
  })
}
