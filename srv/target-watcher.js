import fs from 'fs'
import path from 'path'

export default class TargetWatcher {
  constructor (configPath) {
    this.config = JSON.parse(fs.readFileSync(configPath, 'utf8'))
    this.config.watchFiles = []
    this.timeStamps = []
    this.fillConfigParameters()
    this.findWatchFiles()
    this.setFileWatchInterval()
  }

  setFileWatchInterval () {
    setInterval(() => {
      this.updateTimeStamps()
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
          console.log(`Error in key:${key}, Unknown param ref:${paramKey}`)
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

    // TDOO:
    // search ONLY 1-hierarchy (NOT iterative, deep search)
    fs.readFileSync(sourceFile, 'utf8')
      .split(/\n/)
      .filter(d => !!d.match(/require_relative/))
      .forEach((d) => {
        const result = d.match(/require_relative ['"](.+)['"]/)
        if (result) {
          const childFile = result[1] + '.rb'
          this.config.watchFiles.push(path.join(sourceDir, childFile))
        }
      })
  }

  updateTimeStamps () {
    for (const watchFile of this.config.watchFiles) {
      const stat = fs.statSync(watchFile)
      this.timeStamps.push({
        file: watchFile,
        mtimeMs: stat.mtimeMs,
        mtime: stat.mtime
      })
    }
  }

  getTimeStamps () {
    return JSON.stringify(this.timeStamps)
  }

  getConfig () {
    return JSON.stringify(this.config)
  }
}
