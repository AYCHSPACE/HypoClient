'use strict';

var $ = require('jquery');
module.exports = IFrameManager;

function IFrameManager() {
  this.iframes = {};
  var scriptUrl = 'http://localhost:3001/hypothesis';

  // THESIS TODO: Remove window, for debugging only
  var self = window.self = this;
  var iframes = this.findIFrames();
  this.addIFrames(iframes);
  // this._injectScript(iframes, scriptUrl);

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
  // this._injectScript(iframe, 'http://localhost:3001/hypothesis');

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

// THESIS TODO: Doesn't work with cross origin iframes
IFrameManager.prototype.getIFrameUri = function(iframe) {
  var uri = iframe.contentDocument.location.href;
  return uri;
}

IFrameManager.prototype._injectScript = function(iframe, scriptSrc, i) {
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
