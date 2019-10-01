const path = require('path')

module.exports = {
  pluginOptions: {
    express: {
      shouldServeApp: true,
      serverDir: './srv'
    }
  },
  devServer: {
    watchOptions: {
      ignored: [/model_defs/, /public\/model/]
    }
  },
  configureWebpack: {
    resolve: {
      alias: {
        '~': path.resolve(__dirname, 'netoviz')
      }
    }
  }
}
