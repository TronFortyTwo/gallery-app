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

import QtQuick 2.0
import Gallery 1.0
import "../Capetown"
import "../Capetown/Widgets"
import "../js/GalleryUtility.js" as GalleryUtility
import "Components"
import "Utility"
import "Widgets"

Rectangle {
  id: overview
  objectName: "overview"

  signal albumSelected(variant album, variant thumbnailRect)
  signal eventsCheckerboardHidden(int currScrollPos)
  signal albumEditorCheckerboardHidden(int currScrollPos)

  property Rectangle glass: overviewGlass

  anchors.fill: parent

  function getRectOfAlbumPreview(album, relativeTo) {
    return albumsCheckerboard.getRectOfItemAt(albumsCheckerboard.model.indexOf(album), relativeTo);
  }

  function showAlbumPreview(album, show) {
    var delegate = albumsCheckerboard.getDelegateInstanceAt(albumsCheckerboard.model.indexOf(album));
    if (delegate)
      delegate.visible = show;
  }

  function setCheckerboardScrollPos(newScrollPos) {
    eventsCheckerboard.setScrollPos(newScrollPos);
  }

  function setAlbumEditorScrollPos(newScrollPos) {
    albumEditor.setMediaSelectorScrollPos(newScrollPos);
  }

  state: "eventView"

  states: [
    State { name: "eventView"; },
    State { name: "albumView"; }
  ]

  transitions: [
    Transition { from: "eventView"; to: "albumView";
      DissolveAnimation { fadeOutTarget: eventsSheet; fadeInTarget: albumsCheckerboard; }
    },
    Transition { from: "albumView"; to: "eventView";
      DissolveAnimation { fadeOutTarget: albumsCheckerboard; fadeInTarget: eventsSheet; }
    }
  ]

  Item {
    id: eventsSheet

    anchors.fill: parent

    // if switched away from or to, always move back to checkerboard
    onVisibleChanged: state = "checkerboard"

    // HACK: these shouldn't strictly be necessary.  I want to key the
    // visibility of the children checkerboard/timeline/transition on the
    // transition's timelineFraction property, but when I did that, I was
    // getting weird problems where it looked like the window wasn't refreshing
    // after things' visibilities changed.  This is a little more code, and a
    // little more procedural, but fixes the issue.
    state: "checkerboard"
    states: [
      State { name: "checkerboard"; },
      State { name: "transition"; },
      State { name: "timeline"; }
    ]

    // The EventsCheckerboard has its own background paper, but this will be
    // visible during the timeline and timeline transition.
    Image {
      anchors.fill: parent

      source: "../img/background-paper.png"
      fillMode: Image.Tile
    }

    EventCheckerboard {
      id: eventsCheckerboard
      objectName: "eventsCheckerboard"

      anchors.fill: parent

      topExtraGutter: navbar.height + getDeviceSpecific("photoGridTopMargin")
      bottomExtraGutter: gu(0)
      leftExtraGutter: getDeviceSpecific("photoGridLeftMargin")
      rightExtraGutter: getDeviceSpecific("photoGridRightMargin")

      visible: (eventsSheet.state === "checkerboard")
      allowSelectionModeChange: true

      property variant photoViewerModel: MediaCollectionModel {
        monitored: true
      }

      onActivated: {
        if (objectModel.typeName == "MediaSource") {
          var photoRect = GalleryUtility.translateRect(activatedRect, eventsCheckerboard, photoViewer);
          photoViewer.model = eventsCheckerboard.photoViewerModel;
          photoViewer.animateOpen(object, photoRect, true);
        } else {
          // Event
          eventTimelineTransition.prepare(object, true);
          eventTimelineTransition.finish(true);
          eventsSheet.state = "transition";
        }
      }

      onMovementStarted: {
        scrollOrchestrator.viewMovementStarted(contentY);
      }

      onContentYChanged: {
        scrollOrchestrator.viewScrolled(contentY);
      }

      onMovementEnded: {
        scrollOrchestrator.viewMovementEnded(contentY);
      }

      onVisibleChanged: {
        if (visible) {
          // If we just became visible, it's possible that our scroll position
          // changed due to moving in/out of the timeline view. Let the scroll
          // orchestrator know this so it can keep its state consistent.
          scrollOrchestrator.viewScrolled(contentY);
        }
      }

      // Notify the rest of the app about where we were presently
      // scrolled to when we got hidden.
      onHidden: {
        eventsCheckerboardHidden(currScrollPos);
      }
    }

    EventTimelineTransition {
      id: eventTimelineTransition

      anchors.fill: parent

      visible: (eventsSheet.state === "transition")
      clip: true

      checkerboard: eventsCheckerboard
      timeline: eventTimeline

      onTransitionFinished: (eventsSheet.state = (toTimeline
                                                  ? "timeline"
                                                  : "checkerboard"))
    }

    EventTimeline {
      id: eventTimeline

      anchors.fill: parent

      topExtraGutter: gu(0) + navbar.height
      bottomExtraGutter: gu(0)
      leftExtraGutter: gu(2)
      rightExtraGutter: gu(2)

      visible: (eventsSheet.state === "timeline")
      clip: true

      onActivated: {
        // Event card activated
        eventTimelineTransition.prepare(event, false);
        eventTimelineTransition.finish(false);
        eventsSheet.state = "transition";
      }

      onMovementStarted: scrollOrchestrator.viewMovementStarted(contentY)

      onMovementEnded: scrollOrchestrator.viewMovementEnded(contentY)

      onContentYChanged: scrollOrchestrator.viewScrolled(contentY)
    }
  }

  Checkerboard {
    id: albumsCheckerboard
    objectName: "albumsCheckerboard"

    anchors.fill: parent

    topExtraGutter: navbar.height + getDeviceSpecific("albumGridTopMargin")
    bottomExtraGutter: getDeviceSpecific("albumGridGutterHeight") / 2
    leftExtraGutter: getDeviceSpecific("albumGridLeftMargin")
    rightExtraGutter: getDeviceSpecific("albumGridRightMargin")

    itemWidth: getDeviceSpecific("albumThumbnailWidth")
    itemHeight: getDeviceSpecific("albumThumbnailHeight")
    minGutterWidth: getDeviceSpecific("albumGridGutterWidth")
    minGutterHeight: getDeviceSpecific("albumGridGutterHeight")

    visible: false
    allowSelectionModeChange: false
    singleSelectionOnly: true
    allowActivation: false

    model: AlbumCollectionModel {
    }

    delegate: CheckerboardDelegate {
      property real commitFraction: 0.05

      // internal
      property bool validSwipe: false

      z: (albumThumbnail.isFlipping ? 10 : 0)

      checkerboard: albumsCheckerboard

      contentIsSwipable: album.containedCount > 0

      onSwipeStarted: {
        validSwipe = ((leftToRight && !album.closed) || (!leftToRight && album.closed));
      }

      onSwiping: {
        if (!validSwipe)
          return;

        var availableDistance = (leftToRight) ? (width - start) : start;
        var fraction = Math.max(0, Math.min(1, distance / availableDistance));

        albumThumbnail.openFraction = (leftToRight ? 1 - fraction : fraction);
      }
      
      onLongPressed: {
        albumMenu.show(album)
      }
      
      onSwiped: {
        if (!validSwipe)
          return;

        var fraction = (leftToRight
          ? 1 - albumThumbnail.openFraction
          : albumThumbnail.openFraction);
        if ((leftToRight && fraction >= commitFraction)
          || (!leftToRight && fraction < commitFraction))
          albumThumbnail.close();
        else
          albumThumbnail.open();
      }

      content: AlbumPreviewComponent {
        id: albumThumbnail

        property real maxAddScale: 0.5

        width: albumsCheckerboard.itemWidth
        height: albumsCheckerboard.itemHeight

        album: modelData.album

        // Scale from 1 to 1 + maxAddScale and back to 1 as openFraction goes
        // from 0 to 0.5 to 1.
        scale: 1 + maxAddScale - Math.abs((openFraction - 0.5) * maxAddScale * 2)
      }
    }
    
    onActivated: {
      var albumRect = GalleryUtility.translateRect(activatedRect, albumsCheckerboard, overview);
      albumSelected(object, albumRect);
    }

    onMovementStarted: {
      scrollOrchestrator.viewMovementStarted(contentY);
    }

    onContentYChanged: {
      scrollOrchestrator.viewScrolled(contentY);
    }

    onMovementEnded: {
      scrollOrchestrator.viewMovementEnded(contentY);
    }
  }

  NavbarScrollOrchestrator {
    id: scrollOrchestrator

    navigationBar: navbar

    onInitialized: {
      eventsCheckerboard.contentY = 0;
      albumsCheckerboard.contentY = 0;
    }
  }

  GalleryOverviewNavigationBar {
    id: navbar
    objectName: "navbar"

    y: 0
    anchors.left: parent.left
    anchors.right: parent.right

    visible: !eventsCheckerboard.inSelectionMode

    onAddCreateOperationButtonPressed: {
      if (albumViewSwitcher.isTab0Active) {
        albumEditor.editNewAlbum();
        albumEditorTransition.enterEditor();
      }
    }

    MouseArea {
      anchors.fill: parent
      anchors.leftMargin: gu(10)
      anchors.rightMargin: gu(10)

      onClicked: {
        if (overview.state == "eventView") {
          if (eventsCheckerboard.visible)
            eventsCheckerboard.scrollToTop();
          else if (eventTimeline.visible)
            eventTimeline.scrollToTop();
        } else {
          albumsCheckerboard.scrollToTop();
        }
      }
    }

    BinaryTabGroup {
      id: albumViewSwitcher
      objectName: "albumViewSwitcher"

      anchors.horizontalCenter: parent.horizontalCenter
      anchors.bottom: parent.bottom

      tab0Title: "Albums"
      tab1Title: "Events"

      state: "tab1_active"

      onTab0Activated: {
        scrollOrchestrator.reset();
        overview.state = "albumView";
      }

      onTab1Activated: {
        scrollOrchestrator.reset();
        overview.state = "eventView"
      }
    }
  }

  ViewerChrome {
    id: chrome

    z: 10
    anchors.fill: parent

    autoHideWait: 0

    hasSelectionOperationsButton: eventsCheckerboard.inSelectionMode
    toolbarHasAlbumOperationsButton: false

    inSelectionMode: true
    visible: eventsCheckerboard.inSelectionMode

    popups: ([ selectionOperationsMenu, photoTrashDialog,
              selectionModeShareMenu, selectionModeOptionsMenu ])
    onSelectionOperationsButtonPressed: cyclePopup(selectionOperationsMenu);
    onTrashOperationButtonPressed: cyclePopup(photoTrashDialog);
    onShareOperationsButtonPressed: cyclePopup(selectionModeShareMenu);
    onMoreOperationsButtonPressed: cyclePopup(selectionModeOptionsMenu);

    onSelectionDoneButtonPressed: {
      eventsCheckerboard.unselectAll();
      eventsCheckerboard.inSelectionMode = false;
    }

    SelectionMenu {
      id: selectionOperationsMenu

      checkerboard: eventsCheckerboard

      onPopupInteractionCompleted: chrome.hideAllPopups()
    }
    
    DeleteDialog {
      id: photoTrashDialog

      popupOriginX: -gu(16.5)
      popupOriginY: -gu(6)
      
      actionTitle: eventsCheckerboard.model.selectedCount > 1 ? 
                     "Delete selected items" : "Delete photo"
      
      visible: false

      onDeleteRequested: {
        eventsCheckerboard.model.destroySelectedMedia();

        chrome.hideAllPopups(); // Have to do here since our popup list changes
                                // based on selection mode.
        eventsCheckerboard.unselectAll();
        eventsCheckerboard.inSelectionMode = false;
      }

      onPopupInteractionCompleted: chrome.hideAllPopups()
    }

    GenericShareMenu {
      id: selectionModeShareMenu

      popupOriginX: -gu(8.5)
      popupOriginY: -gu(6)

      onPopupInteractionCompleted: {
        chrome.hideAllPopups();
      }

      visible: false
    }

    SelectionModeOptionsMenu {
      id: selectionModeOptionsMenu

      popupOriginX: -gu(0.5)
      popupOriginY: -gu(6)

      onPopupInteractionCompleted: {
        chrome.hideAllPopups();
      }

      visible: false
    }
  }

  Rectangle {
    id: overviewGlass

    anchors.fill: parent

    color: "black"
    opacity: 0.0
  }
  
  AlbumEditMenu {
    id: albumMenu
    
    visible: false
    state: "hidden"
    
    property Album album
    
    function show(a) {
      album = a;
      var rect = getRectOfAlbumPreview(album, overview);
      if (rect.x <= overview.width / 2)
        popupOriginX = rect.x + rect.width + gu(4);
      else
        popupOriginX = rect.x - childrenRect.width;
      
      popupOriginY = rect.y >= navbar.height ? rect.y : navbar.height;
      state = "shown"
    }
    
    onActionInvoked: {
      // See https://bugreports.qt-project.org/browse/QTBUG-17012 before you
      // edit a switch statement in QML.  The short version is: use braces
      // always.
      switch (name) {
        case "onEdit": {
          albumEditor.editAlbum(album);
          
          showAlbumPreview(album, false);
          var thumbnailRect = getRectOfAlbumPreview(album, overview);
          albumEditorTransition.enterEditor(album, thumbnailRect);
          break;
        }
        
        case "onExport": {
          // TODO
          break;
        }
        
        case "onPrint": {
          // TODO
          break;
        }
        
        case "onShare": {
          // TODO
          break;
        }
        
        case "onDelete": {
          albumTrashDialog.show(album)
          break;
        }
      }
    }
    
    onPopupInteractionCompleted: state = "hidden"
  }
  
  // Dialog for deleting albums.
  DeleteOrDeleteWithContentsDialog {
    id: albumTrashDialog
    
    property variant album: null
    
    visible: false
    
    deleteTitle: "Delete album"
    deleteWithContentsTitle: "Delete album + contents"
    
    function show(albumToShow) {
      album = albumToShow;
      state = "shown"
      
      var rect = getRectOfAlbumPreview(album, overview);
      if (rect.x <= overview.width / 2)
        popupOriginX = rect.x + rect.width + gu(4);
      else
        popupOriginX = rect.x - childrenRect.width;
      
      popupOriginY = rect.y >= navbar.height ? rect.y : navbar.height;
    }
    
    onDeleteRequested: albumsCheckerboard.model.destroyAlbum(album)
    
    onDeleteWithContentsRequested: {
      // Remove contents.
      var list = album.allMediaSources;
      for (var i = 0; i < list.length; i++)
        eventsCheckerboard.model.destroyMedia(list[i]);
      
      // Remove album.
      albumsCheckerboard.model.destroyAlbum(album);
    }
    
    onPopupInteractionCompleted: state = "hidden"
  }
  
  // Cancel out of menus if user clicks outside the menu area.
  MouseArea {
    id: menuCancelArea
    
    anchors.fill: parent
    visible: (albumMenu.state === "shown" || albumTrashDialog.state === "shown")
    acceptedButtons: Qt.LeftButton | Qt.RightButton
    onPressed: {
      albumMenu.state = "hidden";
      albumTrashDialog.state = "hidden";
    }
  }
  
  AlbumEditor {
    id: albumEditor

    anchors.fill: parent

    visible: false

    onMediaSelectorHidden: {
      albumEditorCheckerboardHidden(newScrollPos);
    }

    onCloseRequested: {
      if (album) {
        if (enterViewer) {
          overview.albumSelected(album, null);
          albumEditorTransition.exitEditor(null, null);
        } else {
          var thumbnailRect = overview.getRectOfAlbumPreview(album, albumEditorTransition);

          overview.showAlbumPreview(album, false);
          albumEditorTransition.exitEditor(album, thumbnailRect);
        }
      } else {
        albumEditorTransition.exitEditor(null, null);
      }
    }
  }

  AlbumEditorTransition {
    id: albumEditorTransition

    anchors.fill: parent

    backgroundGlass: overview.glass
    editor: albumEditor

    onEditorExited: overview.showAlbumPreview(album, true)
  }

  PopupPhotoViewer {
    id: photoViewer
    
    anchors.fill: parent
    z: 100
    
    onPhotoChanged: {
      if (photo && eventsCheckerboard.model) {
        eventsCheckerboard.ensureIndexVisible(eventsCheckerboard.model.indexOf(photo),
          false);
      }
    }

    onCloseRequested: {
      var thumbnailRect =
        eventsCheckerboard.getRectOfItemAt(
            eventsCheckerboard.model.indexOf(photo), photoViewer);
      if (thumbnailRect)
        animateClosed(thumbnailRect, true);
      else
        close();
    }
  }
  
  MouseArea {
    id: blocker
    
    anchors.fill: parent
    
    visible: photoViewer.animationRunning || 
      albumEditorTransition.animationRunning || albumEditor.animationRunning
  }
}
