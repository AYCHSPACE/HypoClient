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
    @_cssHref = @_getInjectCSSHref()

    # $("iframe:not('.h-sidebar-iframe')").each (i, iframe) =>
    #   @_iframeAdded(iframe)

  # THESIS TODO: Temporary solution
  _injectCSS: (iframe, href) ->
    linkEl = document.createElement('link')
    linkEl.href = href
    linkEl.rel = "stylesheet"
    linkEl.type = "text/css"
    iframe.contentDocument.head.appendChild(linkEl)

  _getInjectCSSHref: ->
    styleSheets = document.styleSheets
    href = '';
    for own index, styleSheet of styleSheets
      if styleSheet.href && styleSheet.href.includes('inject.css')
        return href = styleSheet.href

    return href

  _iframeAdded: (iframe) ->
    $(iframe).on 'load', =>
      guestElement = iframe.contentDocument.body
      @_injectCSS(iframe, @_cssHref)