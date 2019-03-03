import express from 'express';
import TopologyDataAPI from '../netoviz/srv/topology-data-api'
import TargetWatcher from './target-watcher'

const port = process.env.PORT || 3000 // process.env.PORT for Heroku
const topoDataAPI = new TopologyDataAPI(process.env.NODE_ENV)
const targetWatcher = new TargetWatcher('./srv/target-watcher.json')

export default (app, http) => {
  app.use(express.json())
  app.set('port', port)

  app.post('/watcher/force-update', (req, res) => {
    targetWatcher.generateNewTopologyData()
    res.send('force update request received.')
  })
  app.post('/watcher/config', (req, res) => {
    const config = req.body
    targetWatcher.updateConfig(config)
    res.send('config received.')
  })
  app.get('/watcher/config', (req, res) => {
    res.type('json')
    res.send(targetWatcher.getConfig())
  })
  app.get('/watcher/timestamp', (req, res) => {
    res.type('json')
    res.send(targetWatcher.getTimeStamp())
  })

  app.get('/draw/:jsonName', async (req, res) => {
    res.type('json')
    res.send(await topoDataAPI.convertTopoGraphData(req))
  })
  app.get('/draw-dep-graph/:jsonName', async (req, res) => {
    res.type('json')
    res.send(await topoDataAPI.convertDependencyGraphData(req))
  })
}
