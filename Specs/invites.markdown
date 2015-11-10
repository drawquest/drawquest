# Invites

Spec: https://canvas.atlassian.net/wiki/pages/viewpage.action?pageId=3112967

## New API endpoints
### `/invites/invited_twitter_friends`

- Call this after inviting friends on Twitter. This will begin tracking these users for when they sign up.

**Request:** `twitter_ids`

- `twitter_ids` is a list of twitter user IDs. Make sure you always use the string representation of these IDs to avoid any integer overflow issues (the twitter APIs give you both kinds).

**Response:** empty

- (just the standard success field)

### `/invites/twitter_friends_on_drawquest`
- Tells which Facebook friends of the given user are already on DrawQuest, so that the app can follow those people instead of sending invites/FB app requests.

**Request:** `twitter_access_token`, `twitter_access_token_secret`

**Response:** `users`

- `users` is a list of User dicts (same as other User dicts elsewhere in our API).

### `/invites/facebook_friends_on_drawquest`
**Request**: `facebook_access_token`

**Response**: `users`

- `users` is a list of User dicts (same as other User dicts elsewhere in our API).

### `/auth/login_with_twitter`
**Request**: `twitter_access_token`, `twitter_access_token_secret`

**Response**: empty

- Returns 403 if there's no user with the given Twitter account on DrawQuest.


### `/auth/login_with_facebook`
**Request**: `facebook_access_token`

**Response**: empty

- Returns 403 if there's no user with the given Facebook account on DrawQuest.

### `/auth/associate_twitter_account`
**Request**: `twitter_access_token`, `twitter_access_token_secret`

- Requires the user to be authenticated.

**Response**: empty

- Can return ServiceError if there was an issue communicating with Twitter.

### `/auth/associate_facebook_account`
**Request**: `facebook_access_token`

- Requires the user to be authenticated.

**Response**: empty

- Can return ServiceError if there was an issue communicating with Facebook.


## Activity stream items
There're two new activity stream items, with types `"facebook_friend_joined"` and `"twitter_friend_joined"`. Use the `"actor"` field to see which friend joined.

For the `"facebook_friend_joined"` and `"twitter_friend_joined"` activity items, there's an extra `"name"` field which contains their real name. For `"twitter_friend_joined"` there's also an extra `"twitter_screen_name"` field containing their Twitter username (without any "@" sign).


## Other notes
I've modified `/following/follow_user` to allow the `username` request parameter to be either a string (as it was previously) or a list of strings. If provided with a list of strings, it'll follow each user in the list. You can use this for following a bunch of FB users who already have DQ accounts all at once.


For the URLs we'll send via FB/Twitter/Email, there's an endpoint for generating a share URL to the download page. See the current implementation of email-based invites in 1.0.2 for example usage.

Nothing special has to be done to track invitations with Facebook Requests, I can see the sender of the apprequest once the invitee opens it. I handle deletion of the apprequest as well once it's handled. I just suggest that for the UI, you prepopulate the Requests dialog with the users selected in our checkbox UI, and restrict the total pool of available users (as you're able to add more invitees once the Requests dialog is up) to those who don't appear in the `/invites/facebook_friends_on_drawquest` response.
