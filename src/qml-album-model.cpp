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
 */

#include "qml-album-model.h"

#include <QHash>
#include <QtDeclarative>

QmlAlbumModel::QmlAlbumModel(QObject* parent)
  : QmlViewCollectionModel(parent), album_(NULL) {
}

void QmlAlbumModel::Init(Album* album) {
  album_ = album;
  
  view_.MonitorSourceCollection(album_->pages(), NULL);
  
  QHash<int, QByteArray> roles;
  roles[QmlViewCollectionModel::ObjectNumberRole] = "object_number";
  roles[QmlViewCollectionModel::SelectionRole] = "is_selected";
  roles[MediaPathListRole] = "media_path_list";
  roles[PageNumberRole] = "page_number";
  roles[QmlRcRole] = "qml_rc";
  
  QmlViewCollectionModel::Init(&view_, roles);
}

void QmlAlbumModel::RegisterType() {
  qmlRegisterType<QmlAlbumModel>("org.yorba.qt.qmlalbummodel", 1, 0,
    "QmlAlbumModel");
}

QVariant QmlAlbumModel::DataForRole(DataObject* object, int role) const {
  AlbumPage* page = qobject_cast<AlbumPage*>(object);
  if (page == NULL)
    return QVariant();
  
  switch (role) {
    case MediaPathListRole: {
      QList<QVariant> varlist;
      
      DataObject* object;
      foreach (object, page->contained()->GetAll()) {
        MediaSource* media = qobject_cast<MediaSource*>(object);
        Q_ASSERT(media != NULL);
        
        varlist.append(FilenameVariant(media->file()));
      }
      
      // The QML page is expecting a full list of preview paths, so pack any
      // empty slots with empty strings to prevent a runtime error being logged
      for (int ctr = varlist.count(); ctr < page->template_page()->FrameCount(); ctr++)
        varlist.append(QVariant(""));
      
      return QVariant(varlist);
    }
    
    case PageNumberRole:
      return QVariant(page->page_number());
    
    case QmlRcRole:
      return QVariant(page->template_page()->qml_rc());
    
    default:
      return QVariant();
  }
}
