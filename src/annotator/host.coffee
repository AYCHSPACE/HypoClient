$ = require('jquery')

Guest = require('./guest')

module.exports = class Host extends Guest
  constructor: (element, config) ->
    @allAnchors = []
    @anchorsByUri = {}

    # Some config settings are not JSON-stringifiable (e.g. JavaScript
    # functions) and will be omitted when the config is JSON-stringified.
    # Add a JSON-stringifiable option for each of these so that the sidebar can
    # at least know whether the callback functions were provided or not.
    if config.services?[0]
      service = config.services[0]
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

    # Make a copy of all config settings except `config.app`, the app base URL,
    # and `config.pluginClasses`
    configParam = 'config=' + encodeURIComponent(
      JSON.stringify(Object.assign({}, config, {app:undefined, pluginClasses: undefined }))
    )
    if config.app and '?' in config.app
      config.app += '&' + configParam
    else
      config.app += '?' + configParam

    # Create the iframe
    app = $('<iframe></iframe>')
    .attr('name', 'hyp_sidebar_frame')
    # enable media in annotations to be shown fullscreen
    .attr('allowfullscreen', '')
    .attr('seamless', '')
    .attr('src', config.app)
    .addClass('h-sidebar-iframe')

    @frame = $('<div></div>')
    .css('display', 'none')
    .addClass('annotator-frame annotator-outer')
    .appendTo(element)

    config.isDefaultFrame = true;

    super

    app.appendTo(@frame)

    @crossframe.on 'panelReady', (isDefaultFrame) =>
      # Initialize tool state.
      if config.showHighlights == undefined
        # Highlights are on by default.
        config.showHighlights = 'always'
      this.setAllVisibleHighlights(config.showHighlights == 'always')

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

  scrollToAnnotation: (tag) ->
    @crossframe.call('scrollToAnnotation', tag)

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
