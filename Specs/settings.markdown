# Settings API

## `/user/set_web_profile_privacy`

The current privacy level will be reported in the `heavy_state_sync` endpoint for logged-in users, under the `web_profile_privacy` field, which will be either true or false.

### Request

Required field: `privacy`

`privacy` is a string that can be either `true` or `false`, indicating whether it should be private (`true` meaning the profile is private).

Requires authentication.

### Response

Empty response.

