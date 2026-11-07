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
            "status": { "name": "In Progress", "id": "3", "statusCategory": { "id": 4, "key": "indeterminate", "colorName": "yellow", "name": "In Progress" } }
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
}
