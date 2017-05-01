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
    @cssHref = @getInjectCSSHref()
    super

    if ReadiumSDK
      @readiumSdkInit(ReadiumSDK)
    else
      hasInit = false
      Object.defineProperty window, 'ReadiumSDK',
        get: -> ReadiumSDK
        set: (value) =>
          ReadiumSDK = value
          unless hasInit then @readiumSdkInit(ReadiumSDK)

  readiumSdkInit: (ReadiumSDK) ->
    if ReadiumSDK.reader
      readium = ReadiumSDK.reader
      loadedSpineItems = readium.getLoadedSpineItems() || []
      setTimeout =>
        for spineItem in loadedSpineItems
          $body = readium.getElement(spineItem.idref, 'body')
          frameDocument = $body?[0].ownerDocument
          if $body?.length && $body.children().length && frameDocument.readyState == 'complete'
            @bindFrameDocument(frameDocument, spineItem)

      @bindEvents(readium)
    else
      ReadiumSDK.once ReadiumSDK.Events.READER_INITIALIZED, (readium) =>
        @bindEvents(readium)

  bindEvents: (readium) ->
    readiumLoadDocEvent = ReadiumSDK.Events.CONTENT_DOCUMENT_LOADED
    readiumUnloadDocEvent = ReadiumSDK.Events.CONTENT_DOCUMENT_UNLOADED

    # All versions of Readium out there should emit the loaded event
    readium.on readiumLoadDocEvent, ($iframe, spineItem) =>
      # But some older versions of Readium don't emit the unloaded event,
      # as a workaround, try to destroy guests that no longer have live documents
      unless readiumUnloadDocEvent
        @destroyDetachedGuests()
        @destroyGuest(spineItem.href)

      @bindFrameDocument($iframe[0].contentDocument, spineItem)

    if readiumUnloadDocEvent
      readium.on readiumUnloadDocEvent, ($iframe, spineItem) =>
        @destroyGuest(spineItem.href)

  bindFrameDocument: (frameDocument, spineItem) ->
    guestElement = frameDocument.body
    # THESIS TODO: the chapter identifier is passed in as the guestId
    # Do we want this id to be more unique?
    @addGuest(guestElement, null, spineItem.href)
    @injectCSS(frameDocument, @cssHref)

  destroyDetachedGuests: ->
    for guestUri, guest of @guests
      unless guest.guestDocument.defaultView
        @destroyGuest(guestUri)


  # THESIS TODO: Temporary solution
  injectCSS: (frameDocument, href) ->
    linkEl = frameDocument.createElement('link')
    linkEl.href = href
    linkEl.rel = "stylesheet"
    linkEl.type = "text/css"
    frameDocument.head.appendChild(linkEl)

  getInjectCSSHref: ->
    styleSheets = document.styleSheets
    href = '';
    for own index, styleSheet of styleSheets
      if styleSheet.href && styleSheet.href.includes('inject.css')
        return href = styleSheet.href

    return href
