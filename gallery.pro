######################################################################
# Automatically generated by qmake (2.01a) Mon Oct 24 15:04:00 2011
######################################################################

isEmpty(PREFIX) {
	PREFIX = /usr/local
}

TEMPLATE = app
TARGET = gallery
DEPENDPATH += . src
INCLUDEPATH += .
CONFIG += qt debug link_pkgconfig
QMAKE_CXXFLAGS += -Werror -Wno-unused-parameter
QT += gui declarative opengl
MOC_DIR = build
OBJECTS_DIR = build
RESOURCES = rc/gallery.qrc
RCC_DIR = build
QMAKE_RESOURCE_FLAGS += -root /rc
PKGCONFIG += exiv2

install.path = $$PREFIX/bin/
install.files = gallery
INSTALLS = install

# Input

SOURCES += \
	src/album.cpp \
	src/album-page.cpp \
	src/album-collection.cpp \
	src/album-template.cpp \
	src/album-template-page.cpp \
	src/album-viewer.cpp \
	src/album-viewer-agent.cpp \
	src/container-source.cpp \
	src/container-source-collection.cpp \
	src/data-collection.cpp \
	src/data-object.cpp \
	src/data-source.cpp \
	src/default-album-template.cpp \
	src/gui-controller.cpp \
	src/main.cpp \
	src/media-collection.cpp \
	src/media-source.cpp \
	src/overview.cpp \
	src/overview-agent.cpp \
	src/photo.cpp \
	src/photo-metadata.cpp \
	src/photo-viewer.cpp \
	src/photo-viewer-agent.cpp \
	src/qml-agent.cpp \
	src/qml-album-model.cpp \
	src/qml-album-collection-model.cpp \
	src/qml-media-model.cpp \
	src/qml-page.cpp \
	src/qml-view-collection-model.cpp \
	src/selectable-view-collection.cpp \
	src/source-collection.cpp \
	src/view-collection.cpp

HEADERS += \
	src/album.h \
	src/album-page.h \
	src/album-collection.h \
	src/album-template.h \
	src/album-template-page.h \
	src/album-viewer.h \
	src/album-viewer-agent.h \
	src/container-source.h \
	src/container-source-collection.h \
	src/data-collection.h \
	src/data-object.h \
	src/data-source.h \
	src/default-album-template.h \
	src/gui-controller.h \
	src/media-collection.h \
	src/media-source.h \
	src/overview.h \
	src/overview-agent.h \
	src/photo.h \
	src/photo-metadata.h \
	src/photo-viewer.h \
	src/photo-viewer-agent.h \
	src/qml-agent.h \
	src/qml-album-model.h \
	src/qml-album-collection-model.h \
	src/qml-media-model.h \
	src/qml-page.h \
	src/qml-view-collection-model.h \
	src/selectable-view-collection.h \
	src/source-collection.h \
	src/view-collection.h


OTHER_FILES += \
	rc/gallery.qrc \
	rc/qml/AlbumPreviewA.qml \
	rc/qml/AlbumPreviewB.qml \
	rc/qml/AlbumViewer.qml \
	rc/qml/BinaryTabGroup.qml \
	rc/qml/Checkerboard.qml \
	rc/qml/FramePortrait.qml \
	rc/qml/NavButton.qml \
	rc/qml/NavToolbar.qml \
	rc/qml/Overview.qml \
	rc/qml/PhotoViewer.qml \
	rc/qml/ReturnButton.qml \
	rc/qml/Tab.qml \
	rc/qml/TabletSurface.qml \
	rc/qml/TopBar.qml \
	rc/qml/ViewerNavigationButton.qml
