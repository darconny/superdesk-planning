# -*- coding: utf-8; -*-
#
# This file is part of Superdesk.
#
# Copyright 2013, 2014, 2015, 2016, 2017 Sourcefabric z.u. and contributors.
#
# For the full copyright and license information, please see the
# AUTHORS and LICENSE files distributed with this source code, or
# at https://www.sourcefabric.org/superdesk/license

from .planning import PlanningResource
from .common import ITEM_EXPIRY, ITEM_STATE, set_item_expiry, WORKFLOW_STATE
from superdesk.services import BaseService
from superdesk.notification import push_notification
from apps.auth import get_user
from superdesk import config
from .item_lock import LOCK_USER, LOCK_SESSION


class PlanningSpikeResource(PlanningResource):
    url = 'planning/spike'
    resource_title = endpoint_name = 'planning_spike'

    datasource = {'source': 'planning'}
    resource_methods = []
    item_methods = ['PATCH']
    privileges = {'PATCH': 'planning_planning_spike'}


class PlanningSpikeService(BaseService):
    def update(self, id, updates, original):
        user = get_user(required=True)

        updates['revert_state'] = original[ITEM_STATE]
        updates[ITEM_STATE] = WORKFLOW_STATE.SPIKED
        set_item_expiry(updates)

        # Mark item as unlocked directly in order to avoid more queries and notifications
        # coming from lockservice.
        updates.update({LOCK_USER: None, LOCK_SESSION: None, 'lock_time': None,
                        'lock_action': None})

        item = self.backend.update(self.datasource, id, updates, original)
        push_notification('planning:spiked', item=str(id), user=str(user.get(config.ID_FIELD)),
                          etag=item['_etag'], revert_state=item['revert_state'])

        return item


class PlanningUnspikeResource(PlanningResource):
    url = 'planning/unspike'
    resource_title = endpoint_name = 'planning_unspike'

    datasource = {'source': 'planning'}
    resource_methods = []
    item_methods = ['PATCH']
    privileges = {'PATCH': 'planning_planning_unspike'}


class PlanningUnspikeService(BaseService):
    def update(self, id, updates, original):
        user = get_user(required=True)

        updates[ITEM_STATE] = original.get('revert_state', WORKFLOW_STATE.IN_PROGRESS)
        updates['revert_state'] = None
        updates[ITEM_EXPIRY] = None

        item = self.backend.update(self.datasource, id, updates, original)
        push_notification('planning:unspiked', item=str(id), user=str(user.get(config.ID_FIELD)))
        return item
