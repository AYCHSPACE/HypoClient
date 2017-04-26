Annotator = require('annotator')
$ = Annotator.$

Guest = require('./guest')

module.exports = class Host extends Annotator
  SHOW_HIGHLIGHTS_CLASS = 'annotator-highlights-always-on'

  constructor: (element, options) ->
    # Make a copy of all options except `options.app`, the app base URL.
    configParam = 'config=' + encodeURIComponent(
      JSON.stringify(Object.assign({}, options, {app:undefined}))
    )
    if options.app and '?' in options.app
      options.app += '&' + configParam
    else
      options.app += '?' + configParam

    # Create the iframe
    app = $('<iframe></iframe>')
    .attr('name', 'hyp_sidebar_frame')
    # enable media in annotations to be shown fullscreen
    .attr('allowfullscreen', '')
    .attr('seamless', '')
    .attr('src', options.app)
    .addClass('h-sidebar-iframe')

    @frame = $('<div></div>')
    .css('display', 'none')
    .addClass('annotator-frame annotator-outer')
    .appendTo(element)

    super

    @guests = {}

    for own name, opts of @options
      if not @plugins[name] and Annotator.Plugin[name]
        @addPlugin(name, opts)

    @defaultGuest = @addGuest(element, options)
    @crossframe = @defaultGuest.getCrossframe()
    @adderCtrl = @defaultGuest.getAdderCtrl()
    @plugins.CrossFrame = @crossframe

    app.appendTo(@frame)

    this.on 'panelReady', =>
      # Initialize tool state.
      if options.showHighlights == undefined
        # Highlights are on by default.
        options.showHighlights = true
      this.setVisibleHighlights(options.showHighlights)

      # Show the UI
      @frame.css('display', '')

    this.on 'beforeAnnotationCreated', (annotation) ->
      # When a new non-highlight annotation is created, focus
      # the sidebar so that the text editor can be focused as
      # soon as the annotation card appears
      if !annotation.$highlight
        app[0].contentWindow.focus()

  addGuest: (guestElement, guestOptions, guestId) ->
    options = guestOptions || {}
    if @crossframe then options.crossframe = @crossframe
    if @adderCtrl then options.adderCtrl = @adderCtrl
    if !options.showHighlights then options.showHighlights = @visibleHighlights

    # Give an id if no guestId is provided
    # Note: Does not solve the scenario where two guests share the same document
    if !guestId
      guestId = guestElement.ownerDocument.location.href
    else
    # THESIS TODO: Think of a better name
      # If a guestId is passed in, then the guest must know it's a custom ID
      options.hasCustomId = true
    options.guestId = guestId

    # THESIS TODO: Consider decoupling the BucketBar from the Guest
    options.plugins = {
        BucketBar: @plugins.BucketBar,
    }
    # If this is the default guest, give it the host's document plugin
    if !@defaultGuest
      options.isDefault = true
      options.plugins.Document = @plugins.Document
    else
      options.isDefault = false

    guest = new Guest(guestElement, options)
    guest.listenTo('anchorsSynced', @updateAnchors.bind(this))
    guest.listenTo('highlightsRemoved', @updateAnchors.bind(this))

    @guests[guestId] = guest
    return guest

  createAnnotation: ->
    foundSelected = false
    # Iterate through the guests, and check if any of them have a selection
    # If so, create an annotation with said guest
    for guestId, guest of @guests
      if guest.hasSelection()
        guest.createAnnotation()
        foundSelected = true
        return

    # If none of the guests have a selection, then we want to make a page note
    if !foundSelected then @defaultGuest.createAnnotation()

  destroy: ->
    @frame.remove()

    for name, plugin of @plugins
      @plugins[name].destroy()

    @destroyAllGuests()

  destroyAllGuests: ->
    for guestId, guest of @guests
      destroyGuest(guestId)

  destroyGuest: (guestId) ->
    @guests[guestId].destroy()
    delete @guests[guestId]

  getAnchors: ->
    anchors = []
    for guestId, guest of @guests
      anchors = anchors.concat(guest.anchors)

    return anchors

  selectAnnotations: (annotations) ->
    guestId = annotations[0].uri
    @guests[guestId].selectAnnotations(annotations)

  setVisibleHighlights: (state) ->
    @visibleHighlights = state

    for guestId, guest of @guests
      guest.setVisibleHighlights(state)

  updateAnchors: ->
    @anchors = @getAnchors()

    return @anchors

