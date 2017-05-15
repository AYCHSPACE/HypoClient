$ = require('jquery')

Guest = require('./guest')
IFrameManager = require('./iframe-manager')

module.exports = class Host

  plugins: {}
  guests: {}

  constructor: (element, options) ->
    @element = $(element)
    this.iFrameManager = new IFrameManager()
    # Make a copy of all options except `options.app`, the app base URL, and `options.pluginClasses`
    configParam = 'config=' + encodeURIComponent(
      JSON.stringify(Object.assign({}, options, {app:undefined, pluginClasses: undefined }))
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

    @pluginClasses = options.pluginClasses
    # Load plugins
    for own name, opts of @options
      if not @plugins[name] and @pluginClasses[name]
        this.addPlugin(name, opts)

    app.appendTo(@frame)

    @defaultGuest = @addGuest(element, options)
    @annotator = @defaultGuest

    # THESIS TODO: Debugging only
    window.host = this
    window.guest = @defaultGuest

    # THESIS TODO: Temporary
    @crossframe = @defaultGuest.crossframe
    this.anchors = @defaultGuest.anchors

    @defaultGuest.on 'panelReady', =>
      # Initialize tool state.
      if options.showHighlights == undefined
        # Highlights are on by default.
        options.showHighlights = true
      @defaultGuest.setVisibleHighlights(options.showHighlights)

      # Show the UI
      @frame.css('display', '')

    self = this
    @defaultGuest.on 'beforeAnnotationCreated', (annotation) ->
      # When a new non-highlight annotation is created, focus
      # the sidebar so that the text editor can be focused as
      # soon as the annotation card appears
      if !annotation.$highlight
        app[0].contentWindow.focus()

  addGuest: (element, options) ->
    options = options || {}
    guestUri = element.ownerDocument.location.href
    options.guestUri = guestUri
    options.events = @events

    guest = new Guest(element, options)
    @guests[guestUri] = guest

    guest

  addPlugin: (name, options) ->
    if @plugins[name]
      console.error("You cannot have more than one instance of any plugin.")
    else
      klass = @pluginClasses[name]
      if typeof klass is 'function'
        @plugins[name] = new klass(@element[0], options)
        @plugins[name].annotator = this
        @plugins[name].pluginInit?()
      else
        console.error("Could not load " + name + " plugin. Have you included the appropriate <script> tag?")
    this # allow chaining

  destroy: ->
    @frame.remove()

