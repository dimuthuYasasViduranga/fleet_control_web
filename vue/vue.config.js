const webpackConfig = {
  plugins: [],
  externals: {
    canvg: 'canvg',
    dompurify: 'dompurify',
  },
};

if (process.env.NODE_ENV === 'node_modules') {
  const BundleAnalyzerPlugin = require('webpack-bundle-analyzer').BundleAnalyzerPlugin;
  console.log('\n[Analyze] Node modules will be analysed and display along with the serve\n');
  webpackConfig.plugins.push(new BundleAnalyzerPlugin());
}

module.exports = {
  configureWebpack: webpackConfig,
};
