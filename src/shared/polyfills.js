'use strict';

// ES2015 polyfills
require('core-js/es6/promise');
require('core-js/es6/set');
require('core-js/fn/array/find');
require('core-js/fn/array/find-index');
require('core-js/fn/array/from');
require('core-js/fn/object/assign');

// ES2017
require('core-js/fn/object/values');

// URL constructor, required by IE 10/11,
// early versions of Microsoft Edge.
try {
  var url = new window.URL('https://hypothes.is');

  // Some browsers (eg. PhantomJS 2.x) include a `URL` constructor which works
  // but is broken.
  if (url.hostname !== 'hypothes.is') {
    throw new Error('Broken URL constructor');
  }
} catch (err) {
  require('js-polyfills/url');
}

// Temporary console log monkey patch, tag with frame id
var id = '';
var token = '';
var console = window.console;
var loggersToPatch = ['debug', 'log', 'info', 'warn', 'error'];
var originalConsoleLoggers = {};
try {
  id = window.location.href.replace(window.top.location.origin, '');
} catch (ignored) {
  id = window.location.href;
}
loggersToPatch.forEach(function (logger) {
  originalConsoleLoggers[logger] = console[logger];
});
function patchLoggers () {
  loggersToPatch.forEach(function (logger) {
    console[logger] = originalConsoleLoggers[logger].bind(console, '[', id, document, token, ']\n');
  });
}
patchLoggers();

Object.defineProperty(window, '__h_discovery_token', {
  get: function () {
    return token;
  },
  set: function (value) {
    token = value;
    patchLoggers();
  },
});