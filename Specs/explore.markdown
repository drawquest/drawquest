# Explore API

Product spec: https://canvas.atlassian.net/wiki/pages/viewpage.action?pageId=14057474


## `/explore/comments`

Returns interesting drawings.

### Request

No request parameters.

### Response

Fields: `comments`, `display_size`

`comments` is a list of `comment` dicts. It could be any length. They will contain at least these fields: `id`, `user`, `quest_id`, `content`, and possibly others. The UI should use the `gallery` URL from the `content` dict (which is the same as other `content`s elsewhere) for the small and large thumbnails.

`display_size` is the number of comments to display in the explore page. It will be some value `0 < display_size <= len(comments)`. The app should randomly select that many from the returned set to display.

### Related alerts

When a user gets featured in the Explore section, we send a push notification and an activity stream item. Both have the type `featured_in_explore` and contain a `comment_id`. Responding to either alert should go to the Explore page. You'll be able to find their comment in the `/explore/comments` response, to insert in the first container on the page.

## `/search/users`

This endpoint lives under a different hostname, since search gets its own server: `https://search.api.example.com/search/users`

### Request

Field: `query`

`query` is a string containing whatever the user typed into the search field.

### Response

Field: `users`

`users` is a list of dicts which contain the following fields: `user`, `follower_count`, `following_count`, `viewer_is_following`.

The `viewer_is_following` field is optional. If absent, it means the app should not show a follow/following button for that search result.

The `user` field is a dict identical to other `user` dicts returned throughout the API, which contains: `id`, `username`, and optionally: `avatar_url` if they have one set.

`is_following` is a boolean indicating whether the user who performed the search is following that user.

