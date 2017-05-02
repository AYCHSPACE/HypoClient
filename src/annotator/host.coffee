Annotator = require('annotator')
$ = Annotator.$
Guest = require('./guest')

adder = require('./adder')
extend = require('extend')

module.exports = class Host extends Annotator
  SHOW_HIGHLIGHTS_CLASS = 'annotator-highlights-always-on'

  html: extend {}, Annotator::html,
    adder: '<hypothesis-adder></hypothesis-adder>';

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
    @anchors = {}

    for own name, opts of @options
      if not @plugins[name] and Annotator.Plugin[name]
        @addPlugin(name, opts)

    cfOptions =
      on: (event, handler) =>
        this.subscribe(event, handler)
      emit: (event, args...) =>
        this.publish(event, args)

    @addPlugin('CrossFrame', cfOptions)
    @crossframe = @plugins.CrossFrame
    @crossframe.onConnect(=> @publish('panelReady'))
    @adderCtrl = new adder.Adder(@adder[0])

    @defaultGuest = @addGuest(element, options)
    @plugins.CrossFrame = @crossframe

    @_connectAnnotationSync(@crossframe)
    @_connectAnnotationUISync(@crossframe)

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

  addGuest: (guestElement, guestOptions, guestUri) ->
    options = guestOptions || {}
    options.crossframe = @crossframe
    options.adderCtrl = @adderCtrl
    options.showHighlights = @visibleHighlights

    # Give an id if no guestUri is provided
    # Note: Does not solve the scenario where two guests share the same document
    if !guestUri
      guestUri = guestElement.ownerDocument.location.href
    else
      options.hasCustomUri = true

    options.guestUri = guestUri

    options.plugins = {}
    # If this is the default guest, give it the host's document plugin
    if !@defaultGuest
      options.isDefault = true
      options.plugins.Document = @plugins.Document
    else
      options.isDefault = false
      @plugins.BucketBar?.subscribe(guestElement.ownerDocument)

    guest = new Guest(guestElement, options)
    guest.listenTo('anchorsSynced', @updateAnchors.bind(this))
    guest.listenTo('highlightsRemoved', @updateAnchors.bind(this))
    guest.listenTo('beforeAnnotationCreated', @beforeAnnotationCreated.bind(this))

    @guests[guestUri] = guest
    return guest

  beforeAnnotationCreated: (annotations) ->
    @publish('beforeAnnotationCreated', annotations)

  createAnnotation: ->
    foundSelected = false
    # Iterate through the guests, and check if any of them have a selection
    # If so, create an annotation with said guest
    for guestUri, guest of @guests
      if guest.hasSelection()
        guest.createAnnotation()
        foundSelected = true
        return

    # If none of the guests have a selection, then we want to make a page note
    if !foundSelected then @defaultGuest.createAnnotation()

  destroy: ->
    @frame.remove()
    @destroyAllGuests()

    for name, plugin of @plugins
      @plugins[name].destroy()

  destroyAllGuests: ->
    for guestUri, guest of @guests
      destroyGuest(guestUri)

  destroyGuest: (guestUri) ->
    guest = @guests[guestUri]

    @plugins.BucketBar?.unsubscribe(guest.guestDocument)
    guest.destroy()
    delete @guests[guestUri]
    @updateAnchors()

  getAnchors: ->
    anchors = []
    for guestUri, guest of @guests
      anchors = anchors.concat(guest.anchors)

    return anchors

  selectAnnotations: (annotations) ->
    guestUri = annotations[0].uri
    @guests[guestUri].selectAnnotations(annotations)

  # Sets visibleHighlights for ALL guests
  setVisibleHighlights: (state) ->
    @visibleHighlights = state

    for guestUri, guest of @guests
      guest.setVisibleHighlights(state)

    @publish('setVisibleHighlights', state)

  updateAnchors: ->
    @anchors = @getAnchors()
    @plugins.BucketBar?.update()

    return @anchors

  _connectAnnotationSync: (crossframe) ->
    this.subscribe 'annotationDeleted', (annotation) =>
      guestUri = annotation.uri
      if (@guests[guestUri]) then @guests[guestUri].detach(annotation)

    this.subscribe 'annotationsLoaded', (annotations) =>
      for annotation in annotations
        guestUri = annotation.uri
        if (@guests[guestUri]) then @guests[guestUri].anchor(annotation)

  _connectAnnotationUISync: (crossframe) ->
    self = this

    crossframe.on 'focusAnnotations', (tags=[]) =>
      for anchor in @anchors when anchor.highlights?
        toggle = anchor.annotation.$tag in tags
        guestUri = anchor.annotation.uri
        @guests[guestUri].focusAnnotation(anchor, toggle)

    crossframe.on 'scrollToAnnotation', (tag) =>
      for anchor in @anchors when anchor.highlights?
        if anchor.annotation.$tag is tag
          guestUri = anchor.annotation.uri
          self.guests[guestUri].scrollToAnnotation(anchor.highlights[0])

