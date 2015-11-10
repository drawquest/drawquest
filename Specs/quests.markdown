# Quests API

## `/quests/gallery`

The `/quests/comments` endpoint has been renamed to this, except that there's no more `force_comment_id` parameter - use `/quests/gallery_for_comment` for that. (The old one is still there for backwards compatibility.)

### Request

Required field: `quest_id`
Optional field: `page`

### Response

Returns a list of `comment` dicts. Example response:

    {
      "success": true,
      "comments": [
        {
          "reactions": [],
          "timestamp": 1.36258944E9,
          "content": {
            "editor_template": {
              "url": "http://i.drawquestugc.com/ugc/original/ab4ed311ee6b873ce5e520b89e13de39337a8954.png"
            },
            "timestamp": 1.36258944E9,
            "original": {
              "width": 1024,
              "height": 768,
              "name": "original/ab4ed311ee6b873ce5e520b89e13de39337a8954.png",
              "kb": 57
            },
            "gallery": {
              "url": "http://i.drawquestugc.com/ugc/processed/632708d0f45d6a724e05ab8bae6c54f3edf7daba.jpg"
            },
            "activity": {
              "url": "http://i.drawquestugc.com/ugc/processed/dafac229cb9182d2154228e9fc3a2fd5054c4e89.jpg"
            },
            "id": "ab4ed311ee6b873ce5e520b89e13de39337a8954",
            "archive": {
              "url": "http://i.drawquestugc.com/ugc/processed/acee59ad31debbaeba0e6d79dff58440a0f3cc7b.jpg"
            }
          },
          "posted_on_quest_of_the_day": false,
          "user": {
            "username": "iiopoa",
            "avatar_url": "http://i.drawquestugc.com/ugc/processed/8edfa1a0fdb97d32583f9014b9f72e2c1481f513.jpg",
            "id": 206616
          },
          "quest_id": 926,
          "id": 1442810,
          "quest_title": "Give him a smile!"
        }
      ]
    }

This endpoint is paginated, so it will also have a `pagination` field in its response.

##  `/quests/gallery_for_comment`

The same as `/quests/gallery` except that it returns only the page containing the given comment.

This is the replacement for using `/quests/comments` with its optional `force_comment_id` parameter.

### Request

Required field: `comment_id`

### Response

Returns the same format of data as `/quests/gallery`, including the `pagination` field - it's a paginated endpoint, even though you can't specify a `page` parameter in the request.

The `pagination`  a different URL for getting the next/previous pages (the `response["pagination"]["url"]` field will contain the absolute URL for the `/quests/gallery` endpoint). Since the comment could be on any page, the `pagination` field in the response is likely to be somewhere in the middle of the entire gallery, so it will probably have pages before/after.

The comments returned may or may not included the requested comment. If the comment was disabled (and not just curated), it won't be in the response.

##  `/quests/top_gallery`

The same as `/quests/gallery` except without being a paginated endpoint.

### Request

Required field: `quest_id`

### Response

Returns the same format of data as `/quests/gallery`, excluding the `pagination` field. Please honor the comment ordering.

