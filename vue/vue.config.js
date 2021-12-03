module.exports = {
  publicPath: '/fleet-control/',
  configureWebpack: {
    externals: {
      canvg: 'canvg',
      dompurify: 'dompurify',
    },
  },
};
