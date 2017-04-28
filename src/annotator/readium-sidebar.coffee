Sidebar = require('./sidebar')


module.exports = class ReadiumSidebar extends Sidebar
  options:
    Document: {}
    TextSelection: {}
    BucketBar:
      container: '.annotator-frame'
    Toolbar:
      container: '.annotator-frame'

  constructor: (element, options) ->
    ReadiumSDK = window.ReadiumSDK
    options['shiftNativeElements'] = true
    cssHref = @getInjectCSSHref()
    super

    ReadiumSDK.once(ReadiumSDK.Events.READER_INITIALIZED, (readium) =>
      readium.on(ReadiumSDK.Events.CONTENT_DOCUMENT_LOADED, ($iframe, spineItem) =>
        guestElement = $iframe[0].contentDocument.body
        # THESIS TODO: the chapter identifier is passed in as the guestId
        # Do we want this id to be more unique?
        this.addGuest(guestElement, null, spineItem.href)
        @injectCSS($iframe, cssHref)
      )

      readium.on(ReadiumSDK.Events.CONTENT_DOCUMENT_UNLOADED, ($iframe, spineItem) =>
        this.destroyGuest(spineItem.href)
      )
    )

  # THESIS TODO: Temporary solution
  injectCSS: (iframe, href) ->
    linkEl = document.createElement('link')
    linkEl.href = href
    linkEl.rel = "stylesheet"
    linkEl.type = "text/css"
    iframe[0].contentDocument.head.appendChild(linkEl)

  getInjectCSSHref: ->
    styleSheets = document.styleSheets
    href = '';
    for own index, styleSheet of styleSheets
      if styleSheet.href && styleSheet.href.includes('inject.css')
        return href = styleSheet.href

    return href
