'use strict';

var configFrom = require('./config');
require('../shared/polyfills');


// Polyfills

// document.evaluate() implementation,
// required by IE 10, 11
//
// This sets `window.wgxpath`
if (!window.document.evaluate) {
  require('./vendor/wgxpath.install');
}
if (window.wgxpath) {
  window.wgxpath.install();
}

var $ = require('jquery');

// Applications
var Guest = require('./guest');
var Sidebar = require('./sidebar');
var PdfSidebar = require('./pdf-sidebar');
var ReadiumSidebar = require('./readium-sidebar');

var pluginClasses = {
  // UI plugins
  BucketBar: require('./plugin/bucket-bar'),
  Toolbar: require('./plugin/toolbar'),

  // Document type plugins
  PDF: require('./plugin/pdf'),
  Document: require('./plugin/document'),

  // Cross-frame communication
  CrossFrame: require('./plugin/cross-frame'),
};

var appLinkEl =
  document.querySelector('link[type="application/annotator+html"]');
var config = configFrom(window);

$.noConflict(true)(function() {
  var Klass = Sidebar;
  if (window.PDFViewerApplication) {
    Klass = PdfSidebar;
  } else if (window.ReadiumSDK) {
    Klass = ReadiumSidebar;
  }

  if (config.hasOwnProperty('constructor')) {
    Klass = config.constructor;
    if (Klass === "Guest") Klass = Guest;

    delete config.constructor;
  }

  config.pluginClasses = pluginClasses;

  window.annotator = new Klass(document.body, config);
  appLinkEl.addEventListener('destroy', function () {
    appLinkEl.parentElement.removeChild(appLinkEl);
    window.annotator.destroy();
    window.annotator = undefined;
  });
});
