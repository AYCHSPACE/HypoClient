Sidebar = require('./sidebar')
$ = require('jquery')

module.exports = class IframeSidebar extends Sidebar
  options:
    Document: {}
    TextSelection: {}
    BucketBar:
      container: '.annotator-frame'
    Toolbar:
      container: '.annotator-frame'

  constructor: (element, options) ->
    super

    $("iframe:not('.h-sidebar-iframe')").each (i, iframe) =>
      $(iframe).on 'load', =>
        guestElement = iframe.contentDocument.body
        @addGuest(guestElement, null)
        @injectCSS(iframe)

  injectCSS: (iframe) ->
    linkEl = document.createElement('link')
    # THESIS TODO: Temporarily hardcoded. Improve at some point.
    linkEl.href = "http://localhost:3001/hypothesis/1.13.0/build/styles/inject.css?099248"
    linkEl.rel = "stylesheet"
    linkEl.type = "text/css"
    iframe.contentDocument.head.appendChild(linkEl)
