Sidebar = require('./sidebar')
Guest = require('./guest')

module.exports = class ReadiumSidebar extends Sidebar
  options:
    Document: {}
    TextSelection: {}
    BucketBar:
      container: '.annotator-frame'
    Toolbar:
      container: '.annotator-frame'

  guestOptions:
    Readium: {}
    TextSelection: {}

  readiumInstance: null
  guestInstances: {}

  constructor: (element, options) ->
    super
    ReadiumSDK = window.ReadiumSDK
    ReadiumSDK.once ReadiumSDK.Events.READER_INITIALIZED, (readium) =>
      @readiumInstance = readium
      readium.on ReadiumSDK.Events.CONTENT_DOCUMENT_LOADED, ($iframe, spineItem) =>
        guestId = spineItem.idref
        guestElement = $iframe[0].contentDocument.body
        this.addGuest(guestId, guestElement)

      readium.on ReadiumSDK.Events.CONTENT_DOCUMENT_UNLOADED, ($iframe, spineItem) =>
        guestId = spineItem.idref
        this.destroyGuest(guestId)

  addGuest: (id, element) ->
    console.log 'addGuest', id, element

    @guestInstances[id] = new Guest(element, @guestOptions)

  destroyGuest: (id) ->
    console.log 'destroyGuest', id

    @guestInstances[id]?.destroy()
    delete @guestInstances[id]

