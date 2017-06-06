Sidebar = require('./sidebar')


module.exports = class EpubSidebar extends Sidebar
  options:
    Document: {}
    EPUB: {}
    TextSelection: {}
    BucketBar:
      container: '.annotator-frame'
    Toolbar:
      container: '.annotator-frame'

  constructor: (element, options) ->
    super
