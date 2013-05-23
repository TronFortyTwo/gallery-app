# -*- Mode: Python; coding: utf-8; indent-tabs-mode: nil; tab-width: 4 -*-
# Copyright 2012 Canonical
#
# This program is free software: you can redistribute it and/or modify it
# under the terms of the GNU General Public License version 3, as published
# by the Free Software Foundation.


"""Tests the Photo editor of the gallery app."""

from __future__ import absolute_import

from testtools.matchers import Equals, NotEquals
from autopilot.matchers import Eventually

from gallery_app.emulators.photo_viewer import PhotoViewer
from gallery_app.tests import GalleryTestCase

from os.path import exists
import os
from time import sleep

"""
Class for common functionality of the phot viewing and photo editing
"""


class TestPhotoViewerBase(GalleryTestCase):
    @property
    def photo_viewer(self):
        return PhotoViewer(self.app)

    def setUp(self):
        super(TestPhotoViewerBase, self).setUp()
        self.open_first_photo()
        self.reveal_toolbar()

    def open_first_photo(self):
        single_photo = self.photo_viewer.get_first_image_in_event_view()
        self.click_item(single_photo)

        photo_viewer_loader = self.photo_viewer.get_main_photo_viewer_loader()
        self.assertThat(photo_viewer_loader.loaded, Eventually(Equals(True)))

        photo_viewer = self.photo_viewer.get_main_photo_viewer()
        self.assertThat(photo_viewer.visible, Eventually(Equals(True)))


class TestPhotoViewer(TestPhotoViewerBase):

    def setUp(self):
        super(TestPhotoViewer, self).setUp()

    def test_nav_bar_back_button(self):
        """Clicking the back button must close the photo."""
        photo_viewer = self.photo_viewer.get_main_photo_viewer()
        back_button = self.photo_viewer.get_toolbar_cancel_icon()
        self.click_item(back_button)

        self.assertThat(photo_viewer.visible, Eventually(Equals(False)))

    def test_photo_delete_works(self):
        """Clicking the trash button must show the delete dialog."""
        trash_button = self.photo_viewer.get_toolbar_delete_button()

        self.pointing_device.move_to_object(trash_button)
        self.pointing_device.click()

        delete_dialog = self.photo_viewer.get_delete_dialog()
        self.assertThat(delete_dialog.visible, Eventually(Equals(True)))

        cancel_item = self.photo_viewer.get_delete_popover_cancel_item()
        self.click_item(cancel_item)

        self.assertThat(lambda: exists(self.sample_file),
                        Eventually(Equals(True)))

        self.reveal_toolbar()

        self.pointing_device.move_to_object(trash_button)
        self.pointing_device.click()

        delete_dialog = self.photo_viewer.get_delete_dialog()
        self.assertThat(delete_dialog.visible, Eventually(Equals(True)))

        delete_item = self.photo_viewer.get_delete_popover_delete_item()
        self.click_item(delete_item)

        self.assertThat(lambda: exists(self.sample_file),
                        Eventually(Equals(False)))

    # def test_nav_bar_album_picker_button(self):
    #     """Clicking the album picker must show the picker dialog."""
    #     album_button = self.photo_viewer.get_toolbar_album_button()
    #     album_picker = self.photo_viewer.get_popup_album_picker()

    #     self.pointing_device.move_to_object(album_button)
    #     self.pointing_device.click()

    #     self.assertThat(album_picker.visible, Eventually(Equals(True)))

    def test_nav_bar_share_button(self):
        """Clicking the share button must show the share dialog."""
        share_button = self.photo_viewer.get_toolbar_share_button()

        self.click_item(share_button)

        share_menu = self.photo_viewer.get_share_dialog()
        self.assertThat(share_menu.visible, Eventually(Equals(True)))

    def test_nav_bar_edit_button(self):
        """Clicking the edit button must show the edit dialog."""
        edit_button = self.photo_viewer.get_toolbar_edit_button()

        self.click_item(edit_button)

        edit_dialog = self.photo_viewer.get_photo_edit_dialog()
        self.assertThat(edit_dialog.visible, Eventually(Equals(True)))

    def test_double_click_zoom(self):
        """Double clicking an opened photo must zoom it."""
        opened_photo = self.photo_viewer.get_photo_component()

        self.pointing_device.move_to_object(opened_photo)
        self.pointing_device.click()
        self.pointing_device.click()

        self.assertThat(opened_photo.fullyZoomed, Eventually(Equals(True)))

        self.pointing_device.click()
        self.pointing_device.click()

        self.assertThat(opened_photo.fullyUnzoomed, Eventually(Equals(True)))


class TestPhotoEditor(TestPhotoViewerBase):

    def setUp(self):
        super(TestPhotoEditor, self).setUp()
        self.click_edit_button()
        self.ensure_edit_dialog_visible()

    def click_edit_button(self):
        edit_button = self.photo_viewer.get_toolbar_edit_button()
        self.click_item(edit_button)

    def click_rotate_item(self):
        rotate_item = self.photo_viewer.get_rotate_menu_item()
        self.click_item(rotate_item)

    def click_crop_item(self):
        crop_item = self.photo_viewer.get_crop_menu_item()
        self.click_item(crop_item)

    def click_undo_item(self):
        undo_item = self.photo_viewer.get_undo_menu_item()
        self.click_item(undo_item)

    def click_redo_item(self):
        redo_item = self.photo_viewer.get_redo_menu_item()
        self.click_item(redo_item)

    def click_revert_item(self):
        revert_item = self.photo_viewer.get_revert_menu_item()
        self.click_item(revert_item)

    def test_photo_editor_crop(self):
        """Cropping a photo must crop it."""
        old_file_size = os.path.getsize(self.sample_file)

        crop_box = self.photo_viewer.get_crop_interactor()
        item_width = crop_box.width
        item_height = crop_box.height

        self.click_crop_item()

        self.assertThat(crop_box.state, Eventually(Equals("shown")))

        crop_corner = self.photo_viewer.get_top_left_crop_corner()
        x, y, h, w = crop_corner.globalRect
        x = x + w / 2
        y = y + h / 2
        self.pointing_device.drag(x, y,
                                  x + item_width / 2, y + item_height / 2)

        # wait for animation being finished
        crop_overlay = self.photo_viewer.get_crop_overlay()
        self.assertThat(crop_overlay.interpolationFactor,
                        Eventually(Equals(1.0)))

        crop_button = self.photo_viewer.get_crop_overlays_crop_icon()
        self.click_item(crop_button)

        # wait for new photo being set/reloaded, so saving thumbnailing etc.
        # is done
        edit_preview = self.photo_viewer.get_edit_preview()
        new_source = "image://gallery-standard/" + self.sample_file + \
                     "?size_level=1&orientation=1&edit=2"
        self.assertThat(edit_preview.source, Eventually(Equals(new_source)))

        new_file_size = os.path.getsize(self.sample_file)
        self.assertThat(old_file_size > new_file_size, Equals(True))

    def test_photo_editor_rotate(self):
        """Makes sure that the photo editor inside the photo viewer works using
           the rotate function"""
        opened_photo = self.photo_viewer.get_opened_photo()
        item_height = opened_photo.height

        is_landscape = opened_photo.paintedWidth > opened_photo.paintedHeight
        self.assertThat(is_landscape, Equals(True))

        self.click_rotate_item()

        self.assertThat(opened_photo.paintedHeight,
                        Eventually(Equals(item_height)))
        is_landscape = opened_photo.paintedWidth > opened_photo.paintedHeight
        self.assertThat(is_landscape, Equals(False))

        self.reveal_toolbar()
        self.click_edit_button()
        self.click_undo_item()

        self.assertThat(opened_photo.paintedHeight,
                        Eventually(NotEquals(item_height)))
        is_landscape = opened_photo.paintedWidth > opened_photo.paintedHeight
        self.assertThat(is_landscape, Equals(True))

        self.reveal_toolbar()
        self.click_edit_button()
        self.click_redo_item()

        self.assertThat(opened_photo.paintedHeight,
                        Eventually(Equals(item_height)))
        is_landscape = opened_photo.paintedWidth > opened_photo.paintedHeight
        self.assertThat(is_landscape, Equals(False))

        self.reveal_toolbar()
        self.click_edit_button()
        self.click_rotate_item()
        self.reveal_toolbar()
        self.click_edit_button()
        self.click_revert_item()

        self.assertThat(opened_photo.paintedHeight,
                        Eventually(NotEquals(item_height)))
        is_landscape = opened_photo.paintedWidth > opened_photo.paintedHeight
        self.assertThat(is_landscape, Equals(True))

        # give the gallery the time to fully save the photo, and rebuild the
        # thumbnails
        # FIXME using sleep is a dangerous "hackisch" workaround, and should be
        # implemented properly
        sleep(1)

    def test_photo_editor_redo_undo_revert_to_original_states(self):
        undo_item = self.photo_viewer.get_undo_menu_item()
        redo_item = self.photo_viewer.get_redo_menu_item()
        revert_item = self.photo_viewer.get_revert_menu_item()

        self.assertThat(undo_item.enabled, Eventually(Equals(False)))
        self.assertThat(redo_item.enabled, Eventually(Equals(False)))
        self.assertThat(revert_item.enabled, Eventually(Equals(False)))

        self.click_rotate_item()

        self.assertThat(undo_item.enabled, Eventually(Equals(True)))
        self.assertThat(redo_item.enabled, Eventually(Equals(False)))
        self.assertThat(revert_item.enabled, Eventually(Equals(True)))

        self.reveal_toolbar()
        self.click_edit_button()
        self.click_undo_item()

        self.reveal_toolbar()
        self.click_edit_button()
        undo_item = self.photo_viewer.get_undo_menu_item()
        redo_item = self.photo_viewer.get_redo_menu_item()
        revert_item = self.photo_viewer.get_revert_menu_item()

        self.assertThat(undo_item.enabled, Eventually(Equals(False)))
        self.assertThat(redo_item.enabled, Eventually(Equals(True)))
        self.assertThat(revert_item.enabled, Eventually(Equals(False)))

        self.click_redo_item()

        self.assertThat(undo_item.enabled, Eventually(Equals(True)))
        self.assertThat(redo_item.enabled, Eventually(Equals(False)))
        self.assertThat(revert_item.enabled, Eventually(Equals(True)))

        self.reveal_toolbar()
        self.click_edit_button()
        self.click_revert_item()

        self.reveal_toolbar()
        self.click_edit_button()
        undo_item = self.photo_viewer.get_undo_menu_item()
        redo_item = self.photo_viewer.get_redo_menu_item()
        revert_item = self.photo_viewer.get_revert_menu_item()

        self.assertThat(undo_item.enabled, Eventually(Equals(True)))
        self.assertThat(redo_item.enabled, Eventually(Equals(False)))
        self.assertThat(revert_item.enabled, Eventually(Equals(False)))