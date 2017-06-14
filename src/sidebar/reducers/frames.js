'use strict';

var util = require('./util');

function init() {
  return {
    // The list of frames connected to the sidebar app
    frames: [],
  };
}

var update = {
  ADD_FRAME_ANNOTATIONS: function (state, action) {
    var annotationsByUri = {};

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

  ADD_FRAME_CHILD: function (state, action) {
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

  DESTROY_FRAME_CHILD: function (state, action) {
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
 * Add the annotations to their respective frames
 */
function addFrameAnnotations(annotations) {
  return {type: actions.ADD_FRAME_ANNOTATIONS, annotations: annotations};
}

/**
 * Add the child uri to the list of children in the parent
 */
function addFrameChild(frame) {
  return {type: actions.ADD_FRAME_CHILD, frame: frame};
}

/**
 * Add a frame to the list of frames currently connected to the sidebar app.
 */
function connectFrame(frame) {
  annotationUI.addFrameChild(frame);

  return {type: actions.CONNECT_FRAME, frame: frame};
}

/**
 * Remove a frame from the list of frames currently connected to the sidebar app.
 */
function destroyFrame(frame) {
  var annots = frame.annotations;
  var frames = annotationUI.frames().filter(function(f) {
    return f.uri === frame.uri;
  });

  // If two frames share the same uri then don't delete the annotations, because
  // in that scenario we can't figure out which annotation belongs to which frame.
  if (Object.keys(frames).length === 1) {
    annotationUI.removeAnnotations(annots);
  }

  // Remove the child from the parent
  annotationUI.destroyFrameChild(frame);

  return {type: actions.DESTROY_FRAME, frame: frame};
}

/**
 * Remove the specified child from the list of children in the parent
 */
function destroyFrameChild(frame) {
  return {type: actions.DESTROY_FRAME_CHILD, frame: frame};
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

module.exports = {
  init: init,
  update: update,

  actions: {
    addFrameAnnotations: addFrameAnnotations,
    addFrameChild: addFrameChild,
    connectFrame: connectFrame,
    destroyFrame: destroyFrame,
    destroyFrameChild: destroyFrameChild,
    updateFrameAnnotationFetchStatus: updateFrameAnnotationFetchStatus,
  },

  // Selectors
  frames: frames,
};
