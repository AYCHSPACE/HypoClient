var Plugin = require('../plugin');

function EPUB() {
  // Extend off of plugin
  this.prototype = Object.create(Plugin.prototype)
}

EPUB.prototype.getMetadata = function() {

}

EPUB.prototype.uri = function() {
  
}

module.exports = EPUB;