import Foundation

enum JiraFixture {
    static let search = """
    {
      "expand": "schema,names",
      "startAt": 0,
      "maxResults": 50,
      "total": 2,
      "issues": [
        {
          "expand": "operations,versionedRepresentations",
          "id": "10001",
          "self": "https://jira.example.com/rest/api/2/issue/10001",
          "key": "ABC-123",
          "fields": {
            "summary": "Login button stays disabled after a failed request",
            "issuetype": { "self": "https://jira.example.com/rest/api/2/issuetype/10008", "id": "10008", "name": "Bug", "subtask": false },
            "priority": { "self": "https://jira.example.com/rest/api/2/priority/2", "name": "High", "id": "2" },
            "assignee": { "accountId": "712020:abc", "emailAddress": "alex@example.com", "displayName": "Alex", "active": true },
            "updated": "2026-11-06T13:11:45.043+0000",
            "labels": ["ios", "login"],
            "duedate": "2026-11-20",
            "status":{ "name": "In Progress", "id": "3", "statusCategory": { "id": 4, "key": "indeterminate", "colorName": "yellow", "name": "In Progress" } }
          }
        },
        {
          "id": "10002",
          "self": "https://jira.example.com/rest/api/2/issue/10002",
          "key": "ABC-124",
          "fields": {
            "summary": "Onboarding: new welcome screen",
            "issuetype": { "name": "Story" },
            "priority": null,
            "assignee": null,
            "updated": "2026-11-05T08:42:05.017+0000",
            "status": { "name": "To Do", "statusCategory": { "key": "new" } }
          }
        }
      ]
    }
    """

    static let issue = """
    {
      "id": "10003",
      "self": "https://jira.example.com/rest/api/2/issue/10003",
      "key": "ABC-130",
      "fields": {
        "summary": "Crash on launch without a network connection",
        "issuetype": { "name": "Bug" },
        "priority": { "name": "Highest" },
        "assignee": { "displayName": "Sam" },
        "updated": "2026-11-01T10:00:00.000Z",
        "status": { "name": "Done", "statusCategory": { "key": "done" } }
      }
    }
    """

    static let list = """
    [ { "key": "ABC-200", "fields": { "summary": "From a plain list", "status": { "name": "Open", "statusCategory": { "key": "odd" } } } } ]
    """

    static let serverDetails = #"""
    {
      "id": "10001",
      "self": "https://jira.example.com/rest/api/2/issue/10001",
      "key": "ABC-123",
      "fields": {
        "summary": "Login button stays disabled after a failed request",
        "description": "Steps:\r\n1. Open the login screen.\r\n2. Tap Log In.\r\n",
        "reporter": { "name": "sam", "displayName": "Sam" },
        "created": "2026-11-01T09:00:00.000+0000",
        "labels": ["ios", "login"],
        "components": [{ "id": "1", "name": "Auth" }],
        "parent": { "id": "10000", "key": "ABC-100", "fields": { "summary": "Login flow rework", "status": { "name": "In Progress", "statusCategory": { "key": "indeterminate" } } } },
        "subtasks": [{ "id": "10031", "key": "ABC-131", "fields": { "summary": "Add a unit test", "status": { "name": "To Do", "statusCategory": { "key": "new" } } } }],
        "comment": { "comments": [{ "id": "5001", "author": { "displayName": "Alex" }, "body": "Found it.", "created": "2026-11-02T10:00:00.000+0000" }], "maxResults": 1, "total": 1, "startAt": 0 },
        "fixVersions": [{ "id": "20", "name": "2.4.0", "released": false }],
        "duedate": "2026-11-20",
        "resolution": { "id": "1", "name": "Fixed" },
        "issuelinks": [
          { "id": "301", "type": { "id": "10000", "name": "Blocks", "inward": "is blocked by", "outward": "blocks" }, "outwardIssue": { "id": "10040", "key": "ABC-140", "fields": { "summary": "Release 2.4.0 checklist", "status": { "name": "To Do", "statusCategory": { "key": "new" } } } } },
          { "id": "302", "type": { "id": "10000", "name": "Blocks", "inward": "is blocked by", "outward": "blocks" }, "inwardIssue": { "id": "9999", "key": "ABC-99", "fields": { "summary": "Session refresh endpoint", "status": { "name": "Done", "statusCategory": { "key": "done" } } } } },
          { "id": "303", "type": { "id": "10000", "name": "Blocks", "inward": "is blocked by", "outward": "blocks" } }
        ],
        "attachment": [{ "id": "1", "filename": "login-screen.png", "size": 1024 }, { "id": "2", "filename": "console.log" }],
        "timetracking": { "originalEstimate": "4h", "remainingEstimate": "2h 30m", "timeSpent": "1h 30m", "originalEstimateSeconds": 14400, "remainingEstimateSeconds": 9000, "timeSpentSeconds": 5400 },
        "watches": { "self": "https://jira.example.com/rest/api/2/issue/ABC-123/watchers", "watchCount": 3, "isWatching": true }
      }
    }
    """#

    static let cloudDetails = #"""
    {
      "key": "ABC-124",
      "fields": {
        "description": {
          "type": "doc",
          "version": 1,
          "content": [
            { "type": "paragraph", "content": [
              { "type": "text", "text": "The button stays disabled." },
              { "type": "hardBreak" },
              { "type": "text", "text": "After a restart it works.", "marks": [{ "type": "strong" }] }
            ] },
            { "type": "heading", "attrs": { "level": 3 }, "content": [{ "type": "text", "text": "What to check:" }] },
            { "type": "bulletList", "content": [
              { "type": "listItem", "content": [{ "type": "paragraph", "content": [{ "type": "text", "text": "the retry" }] }] },
              { "type": "listItem", "content": [{ "type": "paragraph", "content": [{ "type": "text", "text": "the timeout" }] }] }
            ] },
            { "type": "codeBlock", "attrs": { "language": "swift" }, "content": [{ "type": "text", "text": "let value = 1" }] },
            { "type": "paragraph", "content": [
              { "type": "text", "text": "See " },
              { "type": "mention", "attrs": { "id": "712020:abc", "text": "@Sam", "accessLevel": "" } },
              { "type": "text", "text": " and " },
              { "type": "inlineCard", "attrs": { "url": "https://example.com/spec" } }
            ] }
          ]
        },
        "comment": { "comments": [{ "id": "7", "author": { "accountId": "712020:abc", "displayName": "Sam" }, "body": { "type": "doc", "version": 1, "content": [{ "type": "paragraph", "content": [{ "type": "text", "text": "Fixed on main " }, { "type": "emoji", "attrs": { "shortName": ":thumbsup:", "id": "1f44d", "text": "👍" } }] }] }, "created": "2026-11-03T10:00:00.000+0000" }] }
      }
    }
    """#
}
