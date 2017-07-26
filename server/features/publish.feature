Feature: Publish

    @auth
    Scenario: Publish Event
        When we post to "/products" with success
        """
        {
            "name":"prod-1","codes":"abc,xyz", "product_type": "both"
        }
        """
        And we post to "/subscribers" with success
        """
        {
            "name":"News1","media_type":"media", "subscriber_type": "digital", "sequence_num_settings":{"min" : 1, "max" : 10}, "email": "test@test.com",
            "products": ["#products._id#"],
            "codes": "xyz, abc",
            "destinations": [{"name":"events", "format": "ntb_event", "delivery_type": "File", "config":{"file_path": "/tmp"}}]
        }
        """
        When we post to "/events" with success
        """
        {
            "guid": "123",
            "unique_id": "123",
            "unique_name": "123 name",
            "name": "event 123",
            "slugline": "event-123",
            "definition_short": "short value",
            "definition_long": "long value",
            "pubstatus": "usable",
            "relationships":{
                "broader": "broader value",
                "narrower": "narrower value",
                "related": "related value"
            },
            "dates": {
                "start": "2016-01-02",
                "end": "2016-01-03"
            },
            "subject": [{"qcode": "test qcaode", "name": "test name"}],
            "location": [{"qcode": "test qcaode", "name": "test name"}],
            "event_contact_info": [{"qcode": "test qcaode", "name": "test name"}]
        }
        """

        When we post to "/events/publish"
        """
        {"event": "#events._id#", "etag": "#events._etag#"}
        """
        Then we get OK response
        When we get "/events/#events._id#"
        Then we get existing resource
        """
        {"state": "published"}
        """

        When we get "publish_queue"
        Then we get list with 1 items
        When we transmit items
        Then file exists "/tmp/123-1-None.txt"

    @auth
    Scenario: Publish non existing event
        When we post to "/events/publish"
        """
        {"event": "foo", "etag": "foo"}
        """
        Then we get error 400
        """
        {"_issues": {"event": "__any_value__"}}
        """

    @auth
    Scenario: Publish non usable event
        When we post to "/events" with success
        """
        {
            "guid": "123",
            "unique_id": "123",
            "unique_name": "123 name",
            "name": "event 123",
            "slugline": "event-123",
            "pubstatus": "withhold",
            "dates": {
                "start": "2016-01-02",
                "end": "2016-01-03"
            }
        }
        """
        When we post to "/events/publish"
        """
        {"event": "#events._id#", "etag": "#events._etag#"}
        """
        Then we get error 409

    @auth
    Scenario: Publish canceled event
        When we post to "/products" with success
        """
        {
            "name":"prod-1","codes":"abc,xyz", "product_type": "both"
        }
        """
        And we post to "/subscribers" with success
        """
        {
            "name":"News1","media_type":"media", "subscriber_type": "digital", "sequence_num_settings":{"min" : 1, "max" : 10}, "email": "test@test.com",
            "products": ["#products._id#"],
            "codes": "xyz, abc",
            "destinations": [{"name":"events", "format": "ntb_event", "delivery_type": "File", "config":{"file_path": "/tmp"}}]
        }
        """
        When we post to "/events" with success
        """
        {
            "guid": "123",
            "unique_id": "123",
            "unique_name": "123 name",
            "name": "event 123",
            "slugline": "event-123",
            "definition_short": "short value",
            "definition_long": "long value",
            "pubstatus": "canceled",
            "relationships":{
                "broader": "broader value",
                "narrower": "narrower value",
                "related": "related value"
            },
            "dates": {
                "start": "2016-01-02",
                "end": "2016-01-03"
            },
            "subject": [{"qcode": "test qcaode", "name": "test name"}],
            "location": [{"qcode": "test qcaode", "name": "test name"}],
            "event_contact_info": [{"qcode": "test qcaode", "name": "test name"}]
        }
        """

        When we post to "/events/publish"
        """
        {"event": "#events._id#", "etag": "#events._etag#"}
        """
        Then we get OK response

        When we get "/events/#events._id#"
        Then we get existing resource
        """
        {"state": "killed"}
        """

        When we transmit items
        Then file exists "/tmp/123-1-None.txt"