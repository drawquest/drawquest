# Comments API

## `/quest_comments/delete`

Deletes a given comment.

https://canvas.atlassian.net/wiki/pages/viewpage.action?pageId=15335426&focusedCommentId=15335427

### Request

Fields: `comment_id`

### Response

No response fields. Will return a ValidationError if the logged-in user didn't author the given comment.

