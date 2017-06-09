EpubSidebar = require('./epub-sidebar')


module.exports = class ReadiumSidebar extends EpubSidebar
  constructor: (element, options) ->
    ReadiumSDK = window.ReadiumSDK
    super

    ReadiumSDK.once(ReadiumSDK.Events.READER_INITIALIZED, (readium) =>
      readium.on(ReadiumSDK.Events.CONTENT_DOCUMENT_LOADED, ($iframe, spineItem) =>
        # @crossframe.discoverOwnFrames()
      )
    )
