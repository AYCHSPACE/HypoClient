'use strict';

/**
 * Returns true if the start point of a selection occurs after the end point,
 * in document order.
 */
function isSelectionBackwards(selection) {
  if (selection.focusNode === selection.anchorNode) {
    return selection.focusOffset < selection.anchorOffset;
  }

  var range = selection.getRangeAt(0);
  return range.startContainer === selection.focusNode;
}

/**
 * Returns true if `node` lies within a range.
 *
 * This is a simplified version of `Range.isPointInRange()` for compatibility
 * with IE.
 *
 * @param {Range} range
 * @param {Node} node
 */
function isNodeInRange(range, node) {
  if (node === range.startContainer || node === range.endContainer) {
    return true;
  }

  var nodeRange = node.ownerDocument.createRange();
  nodeRange.selectNode(node);
  var isAtOrBeforeStart =
    range.compareBoundaryPoints(Range.START_TO_START, nodeRange) <= 0;
  var isAtOrAfterEnd =
    range.compareBoundaryPoints(Range.END_TO_END, nodeRange) >= 0;
  nodeRange.detach();
  return isAtOrBeforeStart && isAtOrAfterEnd;
}

/**
 * Iterate over all Node(s) in `range` in document order and invoke `callback`
 * for each of them.
 *
 * @param {Range} range
 * @param {Function} callback
 */
function forEachNodeInRange(range, callback) {
  var root = range.commonAncestorContainer;

  // The `whatToShow`, `filter` and `expandEntityReferences` arguments are
  // mandatory in IE although optional according to the spec.
  var nodeIter = root.ownerDocument.createNodeIterator(root,
    NodeFilter.SHOW_ALL, null /* filter */, false /* expandEntityReferences */);

  var currentNode;
  while (currentNode = nodeIter.nextNode()) { // eslint-disable-line no-cond-assign
    if (isNodeInRange(range, currentNode)) {
      callback(currentNode);
    }
  }
}

/**
 * Returns the bounding rectangles of non-whitespace text nodes in `range`.
 *
 * @param {Range} range
 * @return {Array<Rect>} Array of bounding rects in viewport coordinates.
 */
function getTextBoundingBoxes(range) {
  var whitespaceOnly = /^\s*$/;
  var textNodes = [];
  forEachNodeInRange(range, function (node) {
    if (node.nodeType === Node.TEXT_NODE &&
        !node.textContent.match(whitespaceOnly)) {
      textNodes.push(node);
    }
  });

  var rects = [];
  textNodes.forEach(function (node) {
    var nodeRange = node.ownerDocument.createRange();
    nodeRange.selectNodeContents(node);
    if (node === range.startContainer) {
      nodeRange.setStart(node, range.startOffset);
    }
    if (node === range.endContainer) {
      nodeRange.setEnd(node, range.endOffset);
    }
    if (nodeRange.collapsed) {
      // If the range ends at the start of this text node or starts at the end
      // of this node then do not include it.
      return;
    }

    // Measure the range and translate from viewport to document coordinates
    var viewportRects = Array.from(nodeRange.getClientRects());
    nodeRange.detach();
    rects = rects.concat(viewportRects);
  });
  return rects;
}

/**
 * Returns the rectangle, in viewport coordinates, for the line of text
 * containing the focus point of a Selection.
 *
 * Returns null if the selection is empty.
 *
 * @param {Selection} selection
 * @return {Rect|null}
 */
function selectionFocusRect(selection) {
  if (selection.isCollapsed) {
    return null;
  }
  var textBoxes = getTextBoundingBoxes(selection.getRangeAt(0));
  if (textBoxes.length === 0) {
    return null;
  }

  if (isSelectionBackwards(selection)) {
    return textBoxes[0];
  } else {
    return textBoxes[textBoxes.length - 1];
  }
}

/**
 * Returns the rectangle, in viewport coordinates, for the line of text
 * containing the focus point of a Selection.
 *
 * Returns null if the selection is empty.
 *
 * @param {Selection} selection
 * @return {Rect|null}
 */
function selectionFocusRectX(selection) {
  if (selection.isCollapsed) {
    return null;
  }

  var boundaryPointRange = selection.getRangeAt(0).cloneRange();
  var backwards = isSelectionBackwards(selection);
  // Collapse range to a boundary point based on the selection direction
  boundaryPointRange.collapse(backwards);
  var targetNodeParent = boundaryPointRange.commonAncestorContainer.parentNode;
  var selectionRect = selectionFocusRect(selection);
  var parentRects = Array.from(targetNodeParent.getClientRects());

  var parentRect = parentRects.find(function (rect) {
    return ((selectionRect.left - rect.left) >= 0) && ((selectionRect.top - rect.top) >= 0);
  });

  var selectionLeftOffset = selectionRect.left - parentRect.left;
  var selectionTopOffset = selectionRect.top - parentRect.top;

  console.log(selectionLeftOffset, selectionTopOffset);

  if (targetNodeParent && targetNodeParent.offsetParent) {
    var offsetsRect = traceOffsetsAcrossAllOffsetParents(targetNodeParent);
    console.log(offsetsRect);
    var newRect = new DOMRect(offsetsRect.x + selectionLeftOffset, offsetsRect.y + selectionTopOffset, selectionRect.width, selectionRect.height);
    console.log(newRect);
    return newRect;
  } else {
    return selectionRect;
  }
}

function traceOffsetsAcrossAllOffsetParents(node) {
  if (node.offsetParent) {
    var parentResult = traceOffsetsAcrossAllOffsetParents(node.offsetParent);
    return {
      x: parentResult.x + node.offsetLeft,
      y: parentResult.y + node.offsetTop,
    };
  } else {
    return {
      x: 0,
      y: 0,
    };
  }
}


module.exports = {
  getTextBoundingBoxes: getTextBoundingBoxes,
  isNodeInRange: isNodeInRange,
  isSelectionBackwards: isSelectionBackwards,
  selectionFocusRect: selectionFocusRectX,
};
