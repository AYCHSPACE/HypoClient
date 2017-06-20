'use strict';

var session = require('./session');
var util = require('./util');

var isFeatureEnabled = session.isFeatureEnabled;

function init() {
  return {
    // The list of frames connected to the sidebar app
    frames: [],
  };
}

var update = {
  ADD_TO_PARENT: function (state, action) {
    // If this has a parent, then search for that frame and give it a child
    var parentUri = action.frame.parentUri;
    var frames = state.frames;

    if (parentUri) {
      var parent = frames.find(function(frame) {
        return frame.uri === parentUri;
      });

      if (parent) {
        parent.childUris.push(action.frame.uri);
      }
    }

    return {frames: frames};
  },

  CONNECT_FRAME: function (state, action) {
    return {frames: state.frames.concat(action.frame)};
  },

  DESTROY_FRAME: function (state, action) {
    var index = state.frames.indexOf(action.frame);
    if (index >= 0) {
      state.frames.splice(index, 1);
    }
    return {frames: state.frames};
  },

  REMOVE_FROM_PARENT: function (state, action) {
    // Remove the specified child from its parent
    var parentUri = action.frame.parentUri;
    var frames = state.frames;

    if (parentUri) {
      var parent = frames.find(function(frame) {
        return frame.uri === parentUri;
      });

      if (parent) {
        var childUri = action.frame.uri;
        var index = parent.childUris.findIndex(function(uri) {
          return uri === childUri;
        });

        if (index > -1) {
          // If multiple children share the same uri, then only remove one of them
          parent.childUris.splice(index, 1);
        }
      }
    }

    return {frames: frames};
  },

  UPDATE_FRAME_ANNOTATIONS: function (state, action) {
    var frames = state.frames.map(function (frame) {
      var uri = frame.uri;

      var annotations = action.annotations.filter(function(annotation) {
        return annotation.uri === uri;
      });

      frame.annotations = annotations;
      return frame;
    });

    return {frames: frames};
  },

  UPDATE_FRAME_ANNOTATION_FETCH_STATUS: function (state, action) {
    var frames = state.frames.map(function (frame) {
      var match = (frame.uri && frame.uri === action.uri);
      if (match) {
        return Object.assign({}, frame, {
          isAnnotationFetchComplete: action.isAnnotationFetchComplete,
        });
      } else {
        return frame;
      }
    });
    return {
      frames: frames,
    };
  },
};

var actions = util.actionTypes(update);

/**
 * Add the child uri to the list of children in the parent
 */
function addToParent(frame) {
  return {type: actions.ADD_TO_PARENT, frame: frame};
}

/**
 * Add a frame to the list of frames currently connected to the sidebar app.
 */
function connectFrame(frame) {
  return {type: actions.CONNECT_FRAME, frame: frame};
}

/**
 * Remove a frame from the list of frames currently connected to the sidebar app.
 */
function destroyFrame(frame) {
  return {type: actions.DESTROY_FRAME, frame: frame};
}

/**
 * Remove the specified child from the list of children in the parent
 */
function removeFromParent(frame) {
  return {type: actions.REMOVE_FROM_PARENT, frame: frame};
}

/**
 * Add the annotations to their respective frames
 */
function updateFrameAnnotations(annotations) {
  return {type: actions.UPDATE_FRAME_ANNOTATIONS, annotations: annotations};
}

/**
 * Update the `isAnnotationFetchComplete` flag of the frame.
 */
function updateFrameAnnotationFetchStatus(uri, status) {
  return {
    type: actions.UPDATE_FRAME_ANNOTATION_FETCH_STATUS,
    isAnnotationFetchComplete: status,
    uri: uri,
  };
}

/**
 * Return the list of frames currently connected to the sidebar app.
 */
function frames(state) {
  return state.frames;
}

function searchUrisForFrame(frame, includeDoi) {
  var uris = [frame.uri];

  if (frame.metadata && frame.metadata.documentFingerprint) {
    uris = frame.metadata.link.map(function (link) {
      return link.href;
    });
  }

  if (includeDoi) {
    if (frame.metadata && frame.metadata.link) {
      frame.metadata.link.forEach(function (link) {
        if (link.href.startsWith('doi:')) {
          uris.push(link.href);
        }
      });
    }
  }

  return uris;
}

/**
 * Return the set of URIs that should be used to search for annotations on the
 * current page.
 */
function searchUris(state) {
  var includeDoi = isFeatureEnabled(state, 'search_for_doi');
  return state.frames.reduce(function (uris, frame) {
    return uris.concat(searchUrisForFrame(frame, includeDoi));
  }, []);
}

module.exports = {
  init: init,
  update: update,

  actions: {
    updateFrameAnnotations: updateFrameAnnotations,
    addToParent: addToParent,
    connectFrame: connectFrame,
    destroyFrame: destroyFrame,
    removeFromParent: removeFromParent,
    updateFrameAnnotationFetchStatus: updateFrameAnnotationFetchStatus,
  },

  // Selectors
  frames: frames,
  searchUris: searchUris,
};
