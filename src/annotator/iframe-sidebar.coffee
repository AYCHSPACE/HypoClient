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
    cssHref = @getInjectCSSHref()

    $("iframe:not('.h-sidebar-iframe')").each (i, iframe) =>
      $(iframe).on 'load', =>
        guestElement = iframe.contentDocument.body
        @injectCSS(iframe, cssHref)

  # THESIS TODO: Temporary solution
  injectCSS: (iframe, href) ->
    linkEl = document.createElement('link')
    linkEl.href = href
    linkEl.rel = "stylesheet"
    linkEl.type = "text/css"
    iframe.contentDocument.head.appendChild(linkEl)

  getInjectCSSHref: ->
    styleSheets = document.styleSheets
    href = '';
    for own index, styleSheet of styleSheets
      if styleSheet.href && styleSheet.href.includes('inject.css')
        return href = styleSheet.href

    return href
