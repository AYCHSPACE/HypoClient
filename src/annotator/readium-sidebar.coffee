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
    super

    ReadiumSDK.once(ReadiumSDK.Events.READER_INITIALIZED, (readium) =>
      readium.on(ReadiumSDK.Events.CONTENT_DOCUMENT_LOADED, ($iframe, spineItem) =>
        guestElement = $iframe[0].contentDocument.body
        # THESIS TODO: the chapter identifier is passed in as the guestId
        # Do we want this id to be more unique?
        this.addGuest(guestElement, null, spineItem.href)
        @injectCSS($iframe)
      )

      readium.on(ReadiumSDK.Events.CONTENT_DOCUMENT_UNLOADED, ($iframe, spineItem) =>
        this.destroyGuest(spineItem.href)
      )
    )

  injectCSS: (iframe) ->
    linkEl = document.createElement('link')
    # THESIS TODO: Temporarily hardcoded. Improve at some point.
    linkEl.href = "http://localhost:3001/hypothesis/1.13.0/build/styles/inject.css?099248"
    linkEl.rel = "stylesheet"
    linkEl.type = "text/css"
    iframe[0].contentDocument.head.appendChild(linkEl)
