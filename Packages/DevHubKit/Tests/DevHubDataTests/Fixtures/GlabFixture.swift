import Foundation

enum GlabFixture {
    static let mergeRequests = Data("""
    [
      {
        "iid": 7,
        "title": "Old merged MR",
        "state": "merged",
        "target_branch": "dev"
      },
      {
        "iid": 12,
        "title": "ABC-1: Open MR",
        "state": "opened",
        "draft": true,
        "web_url": "https://gitlab.com/group/app/-/merge_requests/12",
        "author": { "username": "sam" },
        "has_conflicts": true,
        "detailed_merge_status": "need_rebase",
        "target_branch": "main"
      }
    ]
    """.utf8)

    static let closedMergeRequests = Data("""
    [
      { "iid": 3, "title": "First", "state": "closed", "target_branch": "dev" },
      { "iid": 4, "title": "Second", "state": "merged", "target_branch": "dev" }
    ]
    """.utf8)

    static let pipelines = Data("""
    [
      { "status": "running", "web_url": "https://gitlab.com/group/app/-/pipelines/99", "updated_at": "2026-01-02T03:04:05.000Z" },
      { "status": "success", "web_url": null, "updated_at": "2026-01-01T00:00:00Z" }
    ]
    """.utf8)

    static let pipelineWithBadDate = Data("""
    [{ "status": "failed", "updated_at": "yesterday" }]
    """.utf8)

    static let pipelineWithoutDate = Data("""
    [{ "status": "manual" }]
    """.utf8)

    static let empty = Data("[]".utf8)

    static let malformed = Data("{\"message\": \"404 Not Found\"}".utf8)

    static func mergeRequest(state: String, detail: String) -> Data {
        Data("""
        [{ "iid": 1, "title": "MR", "state": "\(state)", "detailed_merge_status": "\(detail)", "target_branch": "dev" }]
        """.utf8)
    }

    static func pipeline(status: String) -> Data {
        Data("[{ \"status\": \"\(status)\" }]".utf8)
    }

    static let todos = Data(#"""
    [{"id":701,"action_name":"mentioned","target_type":"MergeRequest","state":"pending","created_at":"2026-10-30T10:00:00Z","body":"@alex can you check the retry path?","author":{"username":"sam"},"project":{"path_with_namespace":"team/app"},"target":{"iid":12,"title":"ABC-123: Login screen","web_url":"https://gitlab.example.com/team/app/-/merge_requests/12"}},{"id":702,"action_name":"review_requested","target_type":"MergeRequest","state":"pending","created_at":"2026-10-30T09:00:00Z","body":"ABC-120: Profile badges","author":{"username":"kim"},"project":{"path_with_namespace":"team/app"},"target":{"iid":9,"title":"ABC-120: Profile badges","web_url":"https://gitlab.example.com/team/app/-/merge_requests/9"}},{"id":703,"action_name":"assigned","target_type":"Issue","state":"pending","created_at":"2026-10-29T09:00:00Z","body":"Crash on cold start","author":{"username":"lee"},"project":{"path_with_namespace":"team/app"},"target":{"iid":31,"title":"Crash on cold start","web_url":"https://gitlab.example.com/team/app/-/issues/31"}},{"id":704,"action_name":"marked","target_type":"MergeRequest","state":"done","created_at":"2026-10-29T09:00:00Z","body":"x","author":{"username":"lee"},"project":{"path_with_namespace":"team/app"},"target":{"iid":5,"title":"Done","web_url":"https://gitlab.example.com/team/app/-/merge_requests/5"}},{"id":705,"action_name":"mentioned","target_type":"MergeRequest","state":"pending","created_at":"2026-10-29T09:00:00Z","body":"x","author":{"username":"lee"},"project":{"path_with_namespace":"team/other"},"target":{"iid":6,"title":"Other","web_url":"https://gitlab.example.com/team/other/-/merge_requests/6"}}]
    """#.utf8)
}
