import fs from 'fs'
import path from 'path'
import moment from 'moment-timezone'
import { execSync } from 'child_process'
import { promisify } from 'util'

const stat = promisify(fs.stat)

export default class TargetWatcher {
  constructor (configPath) {
    this.config = JSON.parse(fs.readFileSync(configPath, 'utf8'))
    this.config.watchFiles = []
    this.oldTimeStamps = []
    this.currentTimeStamps = []
    this.makeJsonMessage = Buffer.from('')
    this.verifyJsonMessage = Buffer.from('')
    moment.tz.setDefault('Asia/Tokyo') // default time zone
    this.fillConfigParameters()
    this.findWatchFiles()
    this.setFileWatchInterval()
  }

  setFileWatchInterval () {
    setInterval(() => {
      this.updateTimeStamps().then(() => {
        this.existsUpdatedFile() && this.generateNewTopologyData()
      }).catch((error) => {
        throw error
      })
    }, this.config.interval)
  }

  fillConfigParameters () {
    const paramRegex = /.*%(.+)%.*/
    for (const key in this.config) {
      if (!this.config.hasOwnProperty(key) || !isNaN(this.config[key])) {
        continue
      }
      let value = this.config[key]
      let result = value.match(paramRegex)
      while (result) {
        const paramKey = result[1]
        if (!this.config[paramKey]) {
          console.error(`Error in key:${key}, Unknown param ref:${paramKey}`)
        }
        const paramValue = this.config[paramKey]
        console.log(`param found, replace %${paramKey}% -> ${paramValue}`)
        value = value.replace(`%${paramKey}%`, paramValue)
        this.config[key] = value
        result = value.match(paramRegex)
      }
    }
  }

  findWatchFiles () {
    const sourceFile = this.config.sourceFile
    const sourceDir = path.dirname(sourceFile)

    fs.readFile(sourceFile, 'utf8', (error, data) => {
      if (error) {
        throw error
      }
      // search ONLY 1-hierarchy
      // TODO: iterative, deep search
      data.split(/\n/)
        .forEach((d) => {
          const result = d.match(/require_relative ['"](.+)['"]/)
          if (result) {
            const childFile = result[1] + '.rb'
            this.config.watchFiles.push(path.join(sourceDir, childFile))
          }
        })
    })
  }

  async updateTimeStamps () {
    this.oldTimeStamps = this.currentTimeStamps
    this.currentTimeStamps = []
    for (const watchFile of this.config.watchFiles) {
      try {
        const stats = await stat(watchFile)
        this.currentTimeStamps.push({
          file: watchFile,
          mtimeMs: stats.mtimeMs,
          mtime: moment(stats.mtime).format()
        })
      } catch (error) {
        throw error
      }
    }
  }

  existsUpdatedFile () {
    for (const currentTimeStamp of this.currentTimeStamps) {
      const oldTimeStamp = this.oldTimeStamps.find((d) => {
        return d.file === currentTimeStamp.file
      })
      if (oldTimeStamp && oldTimeStamp.mtimeMs < currentTimeStamp.mtimeMs) {
        console.log('found updated file: ', currentTimeStamp.file)
        return true
      }
    }
    return false
  }

  generateNewTopologyData () {
    this.makeJsonMessage = execSync(this.config.makeJsonCommand)
    this.verifyJsonMessage = execSync(this.config.verifyJsonCommand)
    console.log('make JSON: ', this.makeJsonMessage.toString())
    console.log('verify JSON: ', this.verifyJsonMessage.toString())
  }

  getTimeStamp () {
    const stats = fs.statSync(this.config.outputFile)
    return JSON.stringify({
      modelFile: this.config.outputFile,
      mtimeMs: stats.mtimeMs,
      mtime: moment(stats.mtime).format(),
      makeJsonMessage: this.makeJsonMessage.toString(),
      verifyJsonMessage: this.verifyJsonMessage.toString()
    })
  }

  getConfig () {
    return JSON.stringify(this.config)
  }
}
