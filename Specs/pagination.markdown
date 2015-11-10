# Pagination API

Product spec: https://canvas.atlassian.net/wiki/pages/viewpage.action?pageId=14057477

Pagination doesn't have its own endpoints - it's extra optional parameters and extra response fields that apply to other endpoints.

To avoid confusingly overlapping terms, we'll refer to last page as the "bottom" and the front of the collection as the "top".

### Request

Optional parameter to invoke pagination: `offset`

`offset` can be either an integer or the string `"top"`. 

Without this field, paginating endpoints will either return all or some of their contents.

When specifying `offset`, the client must also include a `direction` parameter, which is either `"next"` or `"previous"`. When `offset` is `"top"`, `direction` should always be `"next"`.

### Response

Paginated endpoints will contain a `pagination` field in their response, which looks like the following example:

    "pagination": {
        "url": "https://api.example.com/quests/gallery",
        "offset": 5,
        "next": 11,
        "previous": 4
    },

The app should not understand how to increment/decrement pages - instead it should only ever ask for `"offset": "top"` and then rely on the response fields `next` and `previous` for the values to pass to subsequent `page` requests. If `next` or `previous` are absent in the `pagination` response, it means there is no next and/or previous page. The `offset` field in responses will always be an integer.

The API can return however many or whatever subset of items it likes for paginated collections - the app should respect this under the aim of being data-driven. It's important that the app only pulls next/previous page numbers from the `pagination` field in responses since the API may return e.g. 2 pages if one page was too small.

When getting next/previous pages, the app should use the URL given in the `url` field of a paginated response, which may be different from the URL used initially. This is to allow for endpoints which give a paginated response but do not accept requests for specific pages (e.g. `/quests/gallery_for_comment`), where a different endpoint is used for accessing the other pages.

