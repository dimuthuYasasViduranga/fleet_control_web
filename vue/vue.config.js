const BundleAnalyzerPlugin = require('webpack-bundle-analyzer').BundleAnalyzerPlugin;

const webpackConfig = {
  externals: {
    canvg: 'canvg',
    html2canvas: 'html2canvas',
    dompurify: 'dompurify',
  },
};

if (process.env.NODE_ENV === 'node_modules') {
  console.log('\n[Analyze] Node modules will be analysed and display along with the serve\n')
  webpackConfig.plugins = [new BundleAnalyzerPlugin()];
}

module.exports = {
  configureWebpack: webpackConfig,
};
