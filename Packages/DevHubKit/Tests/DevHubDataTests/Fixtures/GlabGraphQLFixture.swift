import Foundation

enum GlabGraphQLFixture {
    static let projectList = Data("""
    {"data":{"currentUser":{"username":"me"},"project":{"mergeRequests":{"count":250,
      "pageInfo":{"hasNextPage":true,"endCursor":"eyJpZCI6IjIwIn0"},"nodes":[
      {"iid":"21","title":"ABC-5: Login","state":"opened","draft":false,
       "webUrl":"https://gitlab.example.com/team/app/-/merge_requests/21","author":{"username":"sam"},
       "sourceBranch":"feature/login","targetBranch":"dev","conflicts":true,"detailedMergeStatus":"NOT_APPROVED",
       "userNotesCount":3,"notes":{"nodes":[{"id":"gid://gitlab/Note/9","system":false,"author":{"username":"kim"}},{"id":"gid://gitlab/Note/10","system":true,"author":{"username":"bot"}}]},"updatedAt":"2026-01-02T03:04:05Z","createdAt":"2025-12-20T10:00:00Z",
       "mergedAt":null,"closedAt":null,"mergeUser":null,"commitCount":4,
       "diffStatsSummary":{"additions":120,"deletions":30,"fileCount":7},
       "resolvableDiscussionsCount":5,"resolvedDiscussionsCount":2,"divergedFromTargetBranch":true,
       "squashOnMerge":true,"shouldRemoveSourceBranch":false,"diffHeadSha":"abc123","autoMergeEnabled":true,
       "userPermissions":{"canMerge":true,"canApprove":false},
       "headPipeline":{"status":"FAILED","updatedAt":"2026-01-02T03:00:00Z","duration":540,
         "finishedAt":"2026-01-02T03:09:00Z","failedJobsCount":2,"detailedStatus":{"detailsPath":"/team/app/-/pipelines/9"}},
       "approved":true,"approvedBy":{"nodes":[{"username":"kim"}]},
       "reviewers":{"nodes":[{"username":"me","mergeRequestInteraction":{"reviewState":"REQUESTED_CHANGES"}},{"username":"kim","mergeRequestInteraction":{"reviewState":"APPROVED"}},{"username":"lee"}]},
       "assignees":{"nodes":[{"username":"sam"}]},
       "labels":{"nodes":[{"title":"feature"}]}},
      {"iid":"20","title":"Old","state":"merged","sourceBranch":"old","targetBranch":"main","headPipeline":null,
       "mergedAt":"2026-01-01T09:00:00Z","mergeUser":{"username":"kim"}}
    ]}}}}
    """.utf8)

    static let authoredList = Data("""
    {"data":{"currentUser":{"username":"me","authoredMergeRequests":{"count":1,"nodes":[
      {"iid":"5","title":"Mine","state":"opened","sourceBranch":"a","targetBranch":"dev"}
    ]}}}}
    """.utf8)

    static let assignedList = Data("""
    {"data":{"currentUser":{"username":"me","assignedMergeRequests":{"count":0,"nodes":[]}}}}
    """.utf8)

    static let noUser = Data(#"{"data":{"currentUser":null,"project":{"mergeRequests":{"count":0,"nodes":[]}}}}"#.utf8)

    static let noProject = Data(#"{"data":{"currentUser":{"username":"me"},"project":null}}"#.utf8)

    static let failure = Data(#"{"errors":[{"message":"Field 'x' doesn't exist"}]}"#.utf8)

    static let partialFailure = Data("""
    {"data":{"currentUser":{"username":"me","authoredMergeRequests":{"count":1,"nodes":[
      {"iid":"5","title":"Mine","state":"opened","sourceBranch":"a","targetBranch":"dev"}
    ]}}},"errors":[{"message":"Field 'approvedBy' is not available"}]}
    """.utf8)

    static let details = Data("""
    {"data":{"project":{"mergeRequest":{"description":"Adds **login**.",
      "headPipeline":{"duration":540,"jobs":{"nodes":[
        {"id":"gid://gitlab/Ci::Build/71","name":"build-ios","status":"FAILED","webPath":"/team/app/-/jobs/71","duration":130,"allowFailure":false,"failureMessage":"script failure","stage":{"name":"test"}},
        {"id":"gid://gitlab/Ci::Build/70","name":"unit","status":"SUCCESS","webPath":"/team/app/-/jobs/70","duration":310,"allowFailure":false,"failureMessage":null,"stage":{"name":"test"}},
        {"name":"lint","webPath":null,"allowFailure":true,"failureMessage":"","stage":null},
        {"name":null,"webPath":"/team/app/-/jobs/73","stage":{"name":"test"}}
      ]}},
      "discussions":{"nodes":[
      {"id":"d1","resolvable":true,"resolved":false,"notes":{"nodes":[
        {"id":"gid://gitlab/DiffNote/11","body":"Move this","system":false,"createdAt":"2026-01-02T03:00:00Z","author":{"username":"sam"},"position":{"filePath":"App/Login.swift","newLine":null,"oldLine":12}},
        {"body":"Done?","system":false,"createdAt":"2026-01-02T04:00:00Z","author":{"username":"me"},"position":null},
        {"body":"changed the line","system":true,"author":{"username":"me"},"position":null}
      ]}},
      {"id":"d2","resolvable":true,"resolved":true,"notes":{"nodes":[{"body":"ok","system":false,"author":{"username":"kim"},"position":null}]}},
      {"id":"d3","resolvable":false,"resolved":false,"notes":{"nodes":[{"body":"approved","system":true,"author":null,"position":null}]}},
      {"id":"d4","resolvable":true,"resolved":false,"notes":{"nodes":[{"id":"gid://gitlab/DiscussionNote/44","body":"Need a test","system":false,"author":{"username":"kim"},"position":null}]}}
    ]}}}}}
    """.utf8)

    static let autoMergeAccepted = Data(#"{"data":{"mergeRequestAccept":{"errors":[]}}}"#.utf8)

    static let autoMergeRefused = Data(#"{"data":{"mergeRequestAccept":{"errors":["SHA does not match HEAD of source branch"]}}}"#.utf8)

    static let labels = Data(#"{"data":{"project":{"labels":{"nodes":[{"title":"tech"},{"title":"ADR"},{"title":"bugfix"}]}}}}"#.utf8)

    static let created = Data("""
    {"iid":1404,"title":"Draft: ABC-9: Login","state":"opened","draft":true,
     "web_url":"https://gitlab.example.com/team/app/-/merge_requests/1404","author":{"username":"me"},
     "source_branch":"feature/ABC-9","target_branch":"dev","has_conflicts":false,"detailed_merge_status":"preparing",
     "user_notes_count":0,"created_at":"2026-10-17T10:00:00Z","updated_at":"2026-10-17T10:00:01Z",
     "labels":["feature"],"squash":true,"force_remove_source_branch":true,"sha":"abc123"}
    """.utf8)

    static let noMergeRequest = Data(#"{"data":{"project":{"mergeRequest":null}}}"#.utf8)

    static let diffs = Data("""
    [
      {"old_path":"a.swift","new_path":"a.swift","new_file":false,"deleted_file":false,"renamed_file":false,"too_large":false,
       "diff":"@@ -1,2 +1,2 @@\\n-old\\n+new\\n+more\\n context\\n"},
      {"old_path":"b.swift","new_path":"b.swift","new_file":true,"diff":"@@ -0,0 +1 @@\\n+x\\n"},
      {"old_path":"c.swift","new_path":"c.swift","deleted_file":true,"diff":"@@ -1 +0,0 @@\\n-x\\n"},
      {"old_path":"old/d.swift","new_path":"new/d.swift","renamed_file":true,"diff":""},
      {"old_path":"e.png","new_path":"e.png","too_large":true,"diff":""}
    ]
    """.utf8)
}
