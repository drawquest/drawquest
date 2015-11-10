# Sponsorship API

Product spec: https://canvas.atlassian.net/wiki/display/DRAW/Quest+Sponsorship

Any quest dicts (whether returned by `/quests/archive` or elsewhere) may have the following four optional fields: `attribution_copy`, `attribution_username`, `attribution_avatar_url`, all strings.

`attribution_copy` is e.g. "Sponsored by:" and `attribution_username` is typically a username but could be other things in the future.

For linking to the user profile, use the `attribution_username` field.

