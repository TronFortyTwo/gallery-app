/*
 * Copyright (C) 2011 Canonical Ltd
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 3 as
 * published by the Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * Authors:
 * Jim Nelson <jim@yorba.org>
 * Lucas Beeler <lucas@yorba.org>
 */

import QtQuick 1.1

Rectangle {
  property variant mediaSource
  property bool isCropped: false
  property bool isPreview: false
  property bool isZoomable: false
  property bool isAnimate: false
  property int zoomFocusX: 0
  property int zoomFocusY: 0
  property real pinchInteractionStartZoom: 1.0

  // read-only
  property real paintedWidth: image.paintedWidth
  property real paintedHeight: image.paintedHeight
  property bool isLoaded: false

  // treat these properties as constants
  property real kMaxZoomFactor: 2.5
  
  signal loaded()
  
  clip: true

  function zoom(x, y) {
    // if this PhotoComponent isn't zoomable, make sure we're in the unzoomed
    // state then do a short-circuit return
    if (!isZoomable) {
      state = "unzoomed";
      return;
    }

    if (state == "unzoomed") {
      setZoomFocus(constrainToPanRegion(getZoomFocusFromMouse(x, y), kMaxZoomFactor));
      state = "full_zoom";
    } else {
      state = "unzoomed";
      this.clearZoomFocus();
    }
  }

  function pan(x, y) {
    if (state == "unzoomed")
      return;

    setImageTranslation(constrainToPanRegion(makePoint(x, y)));
  }

  function makePoint(x, y) {
    return { "x": x, "y": y };
  }

  function setImageTranslation(p) {
    image.x = p.x;
    image.y = p.y;
  }

  function getImageTranslation() {
    return makePoint(image.x, image.y);
  }

  function getZoomFocus() {
    return makePoint(zoomFocusX, zoomFocusY);
  }

  function constrainToPanRegion(p, regionScaleFactor) {
    if (!regionScaleFactor)
      regionScaleFactor = image.scale;

    var panRegion = { "xMax": (image.paintedWidth * regionScaleFactor - width) / 2,
                      "yMax": (image.paintedHeight * regionScaleFactor - height) / 2,
                      "xMin": (width - (image.paintedWidth * regionScaleFactor)) / 2,
                      "yMin": (height - (image.paintedHeight * regionScaleFactor)) / 2 };

    if (panRegion.xMax < 0)
      panRegion.xMax = 0;

    if (panRegion.yMax < 0)
      panRegion.yMax = 0;

    var pLocal = { "x": p.x, "y": p.y };

    if (pLocal.x < panRegion.xMin)
      pLocal.x = panRegion.xMin;
    if (pLocal.y < panRegion.yMin)
      pLocal.y = panRegion.yMin;
    if (pLocal.x > panRegion.xMax)
      pLocal.x = panRegion.xMax;
    if (pLocal.y > panRegion.yMax)
      pLocal.y = panRegion.yMax;

    return pLocal;
  }

  function getZoomFocusFromMouse(x, y) {
    return makePoint((image.width / 2 - x) * kMaxZoomFactor, (image.height / 2 - y) * kMaxZoomFactor);
  }

  function setZoomFocus(p) {
    zoomFocusX = p.x;
    zoomFocusY = p.y;
  }

  function clearZoomFocus() {
    zoomFocusX = 0;
    zoomFocusY = 0;
  }

  function beginPinchZoom() {
    pinchInteractionStartZoom = image.scale;

    state = "intermediate_zoom";
  }

  function updatePinchZoom(factor) {
    if (state != "intermediate_zoom")
      return;

    var newScale = factor * pinchInteractionStartZoom;
    if (newScale < 1.0)
      newScale = 1.0;
    else if (newScale > kMaxZoomFactor)
      newScale = kMaxZoomFactor;

    image.scale = newScale;
  }

  function endPinchZoom() {
    if (image.scale == 1.0)
      state = "unzoomed";
    else if (image.scale == kMaxZoomFactor)
      state = "full_zoom";
  }

  states: [
    State { name: "unzoomed";
      PropertyChanges { target: image; scale: 1.0; x: 0; y: 0 } },

    State { name: "full_zoom";
      PropertyChanges { target: image; scale: kMaxZoomFactor; x: zoomFocusX; y: zoomFocusY; } },

    State { name: "intermediate_zoom"; }
  ]

  transitions: [
    Transition { from: "*"; to: "unzoomed";
      NumberAnimation { properties: "x, y, scale"; easing.type: Easing.InQuad;
                        duration: 350; } },
    Transition { from: "unzoomed"; to: "full_zoom";
      NumberAnimation { properties: "x, y, scale"; easing.type: Easing.InQuad;
                        duration: 350; } }
  ]

  state: "unzoomed";

  onIsZoomableChanged: {
    if (!isZoomable) {
      state = "unzoomed";
    }
  }

  Image {
    id: image
    objectName: "image"
    
    source: {
      if (!parent.mediaSource)
        return "";
      
      return isPreview ? mediaSource.previewPath : mediaSource.path
    }

    width: parent.width
    height: parent.height
    x: 0
    y: 0
        
    asynchronous: !isAnimate
    cache: !isAnimate
    smooth: !isAnimate
    fillMode: isCropped ? Image.PreserveAspectCrop : Image.PreserveAspectFit
    
    onStatusChanged: {
      if(image.status == Image.Ready) {
        isLoaded = true;
        loaded();
      }
    }
  }
}
