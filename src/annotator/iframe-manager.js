'use strict';

var $ = require('jquery');
var EventEmitter = require('tiny-emitter');
module.exports = IFrameManager;

function IFrameManager() {
  this.iframes = {};
  this.activeIframe = null;
  this.eventEmitter = new EventEmitter();

  // THESIS TODO: Remove window, for debugging only
  var self = window.self = this;
  var iframes = this.findIFrames();
  this.addIFrames(iframes);

  this._observer = new MutationObserver(this._checkForIFrames.bind(this));

  var config = {childList: true, subtree: true};

  this._observer.observe(document.body, config);
}

IFrameManager.prototype.addIFrame = function(iframe, uri) {
  // getIframeUri only works with iframes on the same origin
  // a uri must be passed in for iframes from other domains
  if (!uri) uri = this.getIFrameUri(iframe);

  var container = {
    uri: uri,
    iframe: iframe
  };

  this.iframes[uri] = container;
  var self = this;
  $(iframe).mouseenter(function() {
    self._setActiveIFrame(iframe);
  });
  $(iframe).mouseleave(function() {
    self._setActiveIFrame();
  });
  this.eventEmitter.emit('iFrameAdded', iframe);

  return container;
}

IFrameManager.prototype.addIFrames = function(iframes, uri) {
  var self = this;
  iframes.forEach(function(iframe) {
    self.addIFrame(iframe);
  });
}

// THESIS TODO: Think about how to deal with blobs / false uri's
IFrameManager.prototype.removeIFrame = function(iframe) {
  var self = this;
  $.each(this.iframes, function (key, container) {
    if (container.iframe === iframe) delete self.iframes[key];
  });

  $(iframe).off('mouseenter mouseleave');
  this.eventEmitter.emit('iFrameRemoved', iframe);
}

IFrameManager.prototype.destroy = function() {
  this._observer.disconnect();
}

IFrameManager.prototype.findIFrames = function() {
  var iframes = [];

  $('iframe').each(function(index, iframe) {
    if (iframe.className !== 'h-sidebar-iframe') {
      iframes.push(iframe);
    } 
    // THESIS TODO: the h-sidebar-iframe is from another domain
    // This is here to do simple tests with it, remove at some point
    // else {
    //   debugger;
    // }
  });

  return iframes;
}

IFrameManager.prototype.getActiveIFrame = function() {
  return this.activeIFrame;
}

IFrameManager.prototype.getIFrame = function(uri) {
  var container = this.iframes[uri];
  return container ? container.iframe : false;
}

IFrameManager.prototype.getIFrames = function() {
  return this.iframes;
}

// THESIS TODO: Doesn't work with cross origin iframes
IFrameManager.prototype.getIFrameUri = function(iframe) {
  var uri = iframe.contentDocument.location.href;
  return uri;
}

// THESIS TODO: Currently designed for easy testing. Will need to rethink this later on.
IFrameManager.prototype.injectCss = function(iframe, cssPathFragment, i) {
  var el = document.createElement('link');
  el.href = this._getCSSHref(cssPathFragment);
  el.rel = "stylesheet";
  el.type = "text/css";


  iframe.contentDocument.head.appendChild(el);
}

IFrameManager.prototype.injectScript = function(iframe, scriptSrc, i) {
  if (!iframe) return;

  var iframes;
  if ($.isArray(iframe)) {
    if (!iframe.length) return;
    iframes = iframe;
    i = (i != undefined) ? i : 0;
    iframe = iframes[i];
  }

  var scriptTag = document.createElement('script');
  scriptTag.src = scriptSrc;
  scriptTag.type = "text/javascript";

  iframe.contentDocument.body.appendChild(scriptTag);

  if (iframes && i < iframes.length-1) {
    i++;
    this._injectScript(iframes, scriptSrc, i);
  }
}

IFrameManager.prototype.on = function(eventName, callback) {
  this.eventEmitter.on(eventName, callback);
}

IFrameManager.prototype.off = function(eventName, callback) {
  this.eventEmitter.off(eventName, callback);
}

IFrameManager.prototype._checkForIFrames = function(mutations) {
  var self = this;
  mutations.forEach(function(mutation) {
    var addedNodes = mutation.addedNodes;
    var removedNodes = mutation.removedNodes;

    // Add iframes
    addedNodes.forEach(function(node) {
      if (node.tagName === 'IFRAME' && node.className != 'h-sidebar-iframe') {
        node.addEventListener('load', function() {
          self.addIFrame(node);
        });
      }
    })

    // Remove iframes
    removedNodes.forEach(function(node) {
      if (node.tagName === 'IFRAME') self.removeIFrame(node);
    })
  });
}

IFrameManager.prototype._getCSSHref = function(fragment) {
  var styleSheets = document.styleSheets
  var href = '';
  for (var i in styleSheets) {
    var styleSheet = styleSheets[i];
    if (styleSheets.hasOwnProperty(i) && 
        styleSheet.href && styleSheet.href.includes(fragment)) {
      return href = styleSheet.href;
    }
  }

  return href;
}

IFrameManager.prototype._setActiveIFrame = function(iframe) {
  this.activeIFrame = iframe || null;
  this.eventEmitter.emit('activeIFrameChanged', iframe);
}
