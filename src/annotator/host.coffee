$ = require('jquery')

Bridge = require('../shared/bridge')
Guest = require('./guest')
IFrameManager = require('./iframe-manager')

module.exports = class Host

  plugins: {}
  guests: {}
  anchors: {}

  constructor: (element, options) ->
    @element = $(element)
    this.iFrameManager = new IFrameManager()
    this.iFrameManager.on('iFrameAdded', @_addGuest.bind(this))

    this._bridge = new Bridge()
    uri = window.location.href
    # THESIS TODO: uri used as token for testing, find a real solution
    token = 'http://localhost:3000'

    this._setupBridgeEvents();
    this._bridge.createChannel(window, uri, token)

    # Make a copy of all options except `options.app`, the app base URL, and `options.pluginClasses`
    configParam = 'config=' + encodeURIComponent(
      JSON.stringify(Object.assign({}, options, {app:undefined, pluginClasses: undefined }))
    )
    if options.app and '?' in options.app
      options.app += '&' + configParam
    else
      options.app += '?' + configParam

    # Create the iframe
    @app = $('<iframe></iframe>')
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

    @app.appendTo(@frame)

    @defaultGuest = new Guest(element, options)
    @annotator = @defaultGuest
    iframes = this.iFrameManager.getIFrames()

    for own key, container of iframes
      @_addGuest(container)

    # THESIS TODO: Debugging only
    window.host = this
    window.guest = @defaultGuest

    # THESIS TODO: Temporary
    @crossframe = @defaultGuest.crossframe

    if options.showHighlights == undefined
      # Highlights are on by default.
      options.showHighlights = true
    @visibleHighlights = options.showHighlights

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

  createAnnotation: (annotation = {}) ->
    this._bridge.call('createAnnotation', annotation)

  destroy: ->
    @frame.remove()

  destroyGuest: ->

  getGuestAnchors: ->
    anchors = []
    for uri, guest of @guests
      anchors = anchors.concat(guest.anchors)

    return anchors

  setVisibleHighlights: (state) ->
    @visibleHighlights = state
    this._bridge.call('setVisibleHighlights', state)

  updateAnchors: (anchors) ->
    # @anchors = @getGuestAnchors()
    # @plugins.BucketBar?.update()

  _addGuest: (container) ->
    iframe = container.iframe
    uri = container.uri
    source = iframe.contentWindow
    # THESIS TODO: uri used as token for testing, find a real solution
    token = 'http://localhost:3000'

    this.iFrameManager.injectScript(iframe, 'http://localhost:3001/hypothesis')
    this._bridge.createChannel(source, uri, token)

  _beforeAnnotationCreated: (annotation) ->
    # When a new non-highlight annotation is created, focus
    # the sidebar so that the text editor can be focused as
    # soon as the annotation card appears
    if !annotation.$highlight
      @app[0].contentWindow.focus()

  # THESIS TODO: At some point, ensure guests are properly destroyed
  # Eg. Destroy the channel in _bridge that links to a guest
  _destroyGuest: (uri) ->

  _panelReady: ->
    # Initialize tool state.
    @_bridge.call('setVisibleHighlights', @visibleHighlights)

    # Show the UI
    @frame.css('display', '')

    if @showSidebarImmediately then @show()

  # THESIS TODO: The Bridge doesn't update the RPC after-the-fact
  # All methods need to be added prior to creating the channel
  # Maybe this could use refactoring?
  # Note: Duplicate present in Guest
  _setupBridgeEvents: (events, i) ->
    i = 0 unless i
    if (!events)
      # Events that Host should listen to
      events = [
        {
          name: 'updateAnchors'
          method: @updateAnchors
        },{
          name: 'panelReady'
          method: @_panelReady
        },{
          name: 'beforeAnnotationCreated'
          method: @_beforeAnnotationCreated
        }
      ]

      # THESIS TODO: Temporary
      # Either collapse Host into Sidebar, or find a better solution
      if (@show)
        sidebarEvents = [
          {
            name: 'showSidebar'
            method: @show
          },{
            name: 'hideSidebar'
            method: @hide
          }
        ]
        events = events.concat(sidebarEvents)

    this._bridge.on(events[i].name, events[i].method.bind(this))

    if (i < events.length - 1)
      this._setupBridgeEvents(events, ++i)

