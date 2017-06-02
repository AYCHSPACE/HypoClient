$ = require('jquery')

Guest = require('./guest')

module.exports = class Host extends Guest
  constructor: (element, options) ->
    @allAnchors = []
    @anchorsByUri = {}

    # Some options' values are not JSON-stringifiable (e.g. JavaScript
    # functions) and will be omitted when the options are JSON-stringified.
    # Add a JSON-stringifiable option for each of these so that the sidebar can
    # at least know whether the callback functions were provided or not.
    if options.services?[0]
      service = options.services[0]
      if service.onLoginRequest
        service.onLoginRequestProvided = true
      if service.onLogoutRequest
        service.onLogoutRequestProvided = true
      if service.onSignupRequest
        service.onSignupRequestProvided = true
      if service.onProfileRequest
        service.onProfileRequestProvided = true
      if service.onHelpRequest
        service.onHelpRequestProvided = true

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

    options.isDefaultFrame = true;

    super

    app.appendTo(@frame)

    @crossframe.on 'panelReady', (isDefaultFrame) =>
      # Initialize tool state.
      if options.showHighlights == undefined
        # Highlights are on by default.
        options.showHighlights = 'always'
      this.setAllVisibleHighlights(options.showHighlights == 'always')

      if (isDefaultFrame)
        # Show the UI
        @frame.css('display', '')
        this.publish('panelReady')

    @crossframe.on 'beforeAnnotationCreated', (annotations) =>
      annotation = annotations[0]
      # When a new non-highlight annotation is created, focus
      # the sidebar so that the text editor can be focused as
      # soon as the annotation card appears
      if !annotation.$highlight
        app[0].contentWindow.focus()

    @crossframe.on 'updateAnchors', (anchors) =>
      @_updateAnchors(anchors)

  destroy: ->
    @frame.remove()
    super

  focusGuestAnnotations: (tags, toggle) ->
    @crossframe.call('focusGuestAnnotations', tags, toggle)

  setAllVisibleHighlights: (shouldShowHighlights) ->
    @crossframe.call('setVisibleHighlights', shouldShowHighlights)

    # Lets Toolbar know about this event
    this.publish 'setVisibleHighlights', shouldShowHighlights

  _updateAnchors: (anchors) ->
    uri = anchors[0].annotation.uri
    this.anchorsByUri[uri] = anchors

    # THESIS TODO: Come back to this at some point
    # For now, just refresh allAnchors every time
    @_refreshAllAnchors()
    @plugins.BucketBar?.update()

  _refreshAllAnchors: ->
    @allAnchors = []
    for own key, anchors of @anchorsByUri
      @allAnchors = @allAnchors.concat(anchors)
