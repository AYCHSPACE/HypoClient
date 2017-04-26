'use strict';

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
var Sidebar = require('./sidebar');
var PdfSidebar = require('./pdf-sidebar');
var IframeSidebar = require('./iframe-sidebar');

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
var options = require('./config')(window);

$.noConflict(true)(function() {
  // THESIS TODO: This was changed for the multiple iframe testing page
  var Klass = IframeSidebar; // Sidebar;

  if (window.PDFViewerApplication) {
    Klass = PdfSidebar;
  }

  if (options.hasOwnProperty('constructor')) {
    Klass = options.constructor;
    delete options.constructor;
  }

  options.pluginClasses = pluginClasses;

  window.annotator = new Klass(document.body, options);
  appLinkEl.addEventListener('destroy', function () {
    appLinkEl.parentElement.removeChild(appLinkEl);
    window.annotator.destroy();
    window.annotator = undefined;
  });
});
