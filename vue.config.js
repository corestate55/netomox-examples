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
  }
}
