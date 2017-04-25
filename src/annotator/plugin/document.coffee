Annotator = require('annotator')
require('../vendor/annotator.document')

module.exports = class Document extends Annotator.Plugin.Document

  guestDocument: null

  constructor: (element, options) ->
    super
    @guestDocument = element.ownerDocument

# returns the primary URI for the document being annotated

  uri: =>
    uri = decodeURIComponent @guestDocument.location.href
    for link in @metadata.link
      if link.rel == "canonical"
        uri = link.href
    return uri
