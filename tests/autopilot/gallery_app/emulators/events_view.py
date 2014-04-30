# -*- Mode: Python; coding: utf-8; indent-tabs-mode: nil; tab-width: 4 -*-
# Copyright 2012 Canonical
#
# This program is free software: you can redistribute it and/or modify it
# under the terms of the GNU General Public License version 3, as published
# by the Free Software Foundation.
import ubuntuuitoolkit.emulators

from gallery_app.emulators.gallery_utils import GalleryUtils


class EventsViewException(Exception):
    pass


class EventsView(GalleryUtils):

    def __init__(self, app):
        self.app = app
        self.pointing_device = ubuntuuitoolkit.emulators.get_pointing_device()

    def get_event(self, event_number=0):
        """Return an event in the event view based on index number

        :param event_number: the index number of the organicEventItem to get
        """
        return self.app.select_single(
            'OrganicMediaList',
            objectName='organicEventItem{}'.format(int(event_number))
        )

    def number_of_events(self):
        """Return the number of events in the model behind the event view"""
        return self.app.select_single('EventsOverview')._eventCount

    def number_of_photos_in_events(self):
        """Return the number of events"""

        overview = self.app.select_single('EventsOverview')
        photo_delegates = overview.select_many(
            "QQuickItem",
            objectName="eventPhoto"
        )
        return len(photo_delegates)

    def number_of_photos_in_event(self, event):
        """Return the number of photo delgated in an event"""
        photo_delegates = event.select_many(objectName='eventPhoto')
        return len(photo_delegates)

    def _get_image_in_event_view(self, image_name, event_index_num=0):
        """Return the photo of the gallery based on image name.

        :param image_name: the name of the photo in the event to return"""
        event = self.get_event(event_index_num)
        photos = event.select_many(
            'QQuickItem',
            objectName='eventPhoto'
        )
        for photo in photos:
            images = photo.select_many('QQuickImage')
            for image in images:
                if str(image.source).endswith(image_name):
                    return image
        raise EventsViewException(
            'Photo with image name {} could not be found'.format(image_name))

    def click_photo(self, photo_name, event_index_num=0):
        """Click photo with name and event

        :param photo_name: name of file to click
        :param event_index_num: index of event to click
        """
        photo = self._get_image_in_event_view(photo_name, event_index_num)
        self.pointing_device.click_object(photo)
