const BundleAnalyzerPlugin = require('webpack-bundle-analyzer').BundleAnalyzerPlugin;

module.exports = {
  configureWebpack: {
    plugins: [new BundleAnalyzerPlugin()],
    externals: {
      canvg: 'canvg',
      html2canvas: 'html2canvas',
      dompurify: 'dompurify',
    },
  },
};
