/*
 * Copyright (C) 2012 Canonical Ltd
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

import QtQuick 1.1
import Gallery 1.0

Item {
  id: albumOpener

  // public
  property Album album
  property bool isPreview: false
  property bool contentHasPreviewFrame: false
  property int duration: 1000
  property real openFraction: 0

  // readonly
  property bool isFlipping: (openFraction != 0 && openFraction != 1)
  property alias frameToContentWidth: rightPage.frameToContentWidth
  property alias frameToContentHeight: rightPage.frameToContentHeight

  // internal
  property int currentOrFirstContentPage: (!album
    ? -1
    : (album.currentPage == album.firstValidCurrentPage
      ? album.firstContentPage
      : album.currentPage))

  function open() {
    animator.to = 1;
    animator.restart();
  }

  function close() {
    animator.to = 0;
    animator.restart();
  }

  onAlbumChanged: openFraction = (album.closed ? 0 : 1)

  Connections {
    target: album
    ignoreUnknownSignals: true
    onClosedAltered: openFraction = (album.closed ? 0 : 1)
  }

  Item {
    id: shifter

    x: width * openFraction // Shift it over as it opens so the visuals stay centered.
    y: 0
    width: parent.width
    height: parent.height

    AlbumPageComponent {
      id: rightPage

      anchors.fill: parent
      visible: (openFraction > 0 && openFraction < 1)

      album: albumOpener.album
      frontPage: rightPageForCurrent(currentOrFirstContentPage)
      backPage: (album ? leftPageForCurrent(album.lastValidCurrentPage) : -1)

      isPreview: albumOpener.isPreview
      contentHasPreviewFrame: albumOpener.contentHasPreviewFrame

      flipFraction: (openFraction > 0.5 && openFraction <= 1 ? openFraction * -2 + 3 : 0)
    }

    AlbumPageComponent {
      id: leftPage

      anchors.fill: parent

      album: albumOpener.album
      frontPage: (album ? rightPageForCurrent(album.firstValidCurrentPage) : -1)
      backPage: leftPageForCurrent(currentOrFirstContentPage)

      isPreview: albumOpener.isPreview
      contentHasPreviewFrame: albumOpener.contentHasPreviewFrame

      flipFraction: (openFraction >= 0 && openFraction < 0.5 ? openFraction * 2 : 1)
    }
  }

  NumberAnimation {
    id: animator

    target: albumOpener
    property: "openFraction"
    duration: albumOpener.duration
    easing.type: Easing.OutQuad

    onCompleted: {
      if (openFraction == 0) {
        album.closed = true;
      } else if (openFraction == 1) {
        album.closed = false;
        if (album.currentPage == album.firstValidCurrentPage)
          album.currentPage = album.firstContentPage;
      }
    }
  }
}