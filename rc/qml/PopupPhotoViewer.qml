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
 * Charles Lindsay <chaz@yorba.org>
 */

import QtQuick 2.0
import "../Capetown"

// A PhotoViewer that is opened and closed with the PhotoViewerTransition.
Item {
  id: popupPhotoViewer

  /*!
  */
  property alias model: viewer.model

  /*!
  */
  property alias photo: viewer.photo
  /*!
  */
  property alias index: viewer.index
  
  // Optional: set this when launching from an album view
  property alias album: viewer.album
  
  // Read-only
  property bool animationRunning: transition.animationRunning || 
    fadeIn.running || fadeOut.running
  /*!
  */
  property bool isPoppedUp: viewer.visible && !animationRunning
  
  /*!
  */
  function setCurrentPhoto(photo) {
    viewer.setCurrentPhoto(photo);
  }

  /*!
  */
  function setCurrentIndex(index) {
    viewer.setCurrentIndex(index);
  }
  
  /*!
  */
  signal opening()
  /*!
  */
  signal opened() // The photo viewer's opening animation is finished.
  /*!
  */
  signal closeRequested() // The user pressed the back button.  Call animateClosed() or close().
  /*!
  */
  signal closed() // The photo viewer's closing animation is finished.
  /*!
  */
  signal editRequested(variant photo) // The user wants to edit this photo.

  /*!
  */
  function animateOpen(photo, thumbnailRect) {
    opening();
    viewer.openCompleted = false;
    transition.transitionToPhotoViewer(photo, thumbnailRect);
  }

  /*!
  */
  function animateClosed(thumbnailRect) {
    transition.transitionFromPhotoViewer(photo, thumbnailRect);
    viewer.visible = false;
  }

  /*!
  */
  function fadeOpen(photo) {
    opening();
    viewer.setCurrentPhoto(photo);
    fadeIn.restart();
  }

  /*!
  */
  function fadeClosed() {
    fadeOut.restart();
  }

  /*!
  */
  function close() {
    viewer.visible = false;
    closed();
  }
  
  GalleryPhotoViewer {
    id: viewer
    
    property bool openCompleted: false
    
    anchors.fill: parent
    visible: false

    onCloseRequested: popupPhotoViewer.closeRequested()

    onEditRequested: popupPhotoViewer.editRequested(photo)
    
    onIsReadyChanged: updateVisibility()
    onOpenCompletedChanged: updateVisibility()
    
    // Internal
    function updateVisibility() {
      if (isReady && openCompleted) {
        visible = true;
        transition.hide();
      }
    }
  }

  PhotoViewerTransition {
    id: transition

    anchors.fill: parent

    onTransitionToPhotoViewerCompleted: {
      setCurrentPhoto(forMediaSource);
      viewer.openCompleted = true;
      opened();
    }

    onTransitionFromPhotoViewerCompleted: {
      closed();
    }
  }

  FadeInAnimation {
    id: fadeIn

    target: viewer
    onStopped: {
      opened();
    }
  }

  FadeOutAnimation {
    id: fadeOut

    target: viewer
    onStopped: {
      closed();
    }
  }
}
