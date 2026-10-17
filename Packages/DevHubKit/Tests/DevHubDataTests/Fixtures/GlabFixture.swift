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
}
