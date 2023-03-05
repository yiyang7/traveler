const { override, fixBabelImports, addPostcssPlugins, addLessLoader } = require('customize-cra');
module.exports = override(
  fixBabelImports('import', {
    libraryName: 'antd-mobile',
    style: 'css',
  }),
  addPostcssPlugins(
      [
          require("postcss-px2rem")({remUnit:375/10})
      ]
  )
);
