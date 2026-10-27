import Foundation

enum GhFixture {
    static let list = Data(#"""
    {"data":{"viewer":{"login":"alex"},"repository":{"viewerPermission":"ADMIN","viewerDefaultMergeMethod":"MERGE","deleteBranchOnMerge":false,"autoMergeAllowed":false},"search":{"issueCount":3,"pageInfo":{"hasNextPage":false,"endCursor":"Y3Vyc29yOjM="},"nodes":[{"number":3,"title":"ABC-103: Broken check","state":"OPEN","isDraft":false,"url":"https://github.com/example/app/pull/3","author":{"login":"alex"},"headRefName":"feature/ABC-103-broken","baseRefName":"main","mergeable":"MERGEABLE","mergeStateStatus":"UNSTABLE","reviewDecision":null,"totalCommentsCount":0,"additions":1,"deletions":0,"changedFiles":1,"headRefOid":"ccc333","createdAt":"2026-10-17T22:33:04Z","updatedAt":"2026-10-17T22:33:04Z","mergedAt":null,"closedAt":null,"mergedBy":null,"autoMergeRequest":null,"labels":{"nodes":[]},"latestReviews":{"nodes":[]},"reviewThreads":{"totalCount":0,"nodes":[]},"commitCount":{"totalCount":1},"lastCommit":{"nodes":[{"commit":{"statusCheckRollup":{"state":"FAILURE","contexts":{"nodes":[{"__typename":"CheckRun","name":"notes","conclusion":"FAILURE","status":"COMPLETED","detailsUrl":"https://github.com/example/app/actions/runs/903/job/9031","startedAt":"2026-10-17T22:33:11Z","completedAt":"2026-10-17T22:33:18Z","checkSuite":{"workflowRun":{"databaseId":903}}}]}}}}]}},{"number":1,"title":"ABC-101: Login screen","state":"OPEN","isDraft":false,"url":"https://github.com/example/app/pull/1","author":{"login":"alex"},"headRefName":"feature/ABC-101-login","baseRefName":"main","mergeable":"MERGEABLE","mergeStateStatus":"CLEAN","reviewDecision":null,"totalCommentsCount":2,"additions":3,"deletions":1,"changedFiles":2,"headRefOid":"aaa111","createdAt":"2026-10-17T22:30:37Z","updatedAt":"2026-10-17T22:33:02Z","mergedAt":null,"closedAt":null,"mergedBy":null,"autoMergeRequest":null,"labels":{"nodes":[{"name":"feature"}]},"latestReviews":{"nodes":[]},"reviewThreads":{"totalCount":1,"nodes":[{"isResolved":false}]},"commitCount":{"totalCount":2},"lastCommit":{"nodes":[{"commit":{"statusCheckRollup":{"state":"SUCCESS","contexts":{"nodes":[{"__typename":"CheckRun","name":"notes","conclusion":"SUCCESS","status":"COMPLETED","detailsUrl":"https://github.com/example/app/actions/runs/901/job/9011","startedAt":"2026-10-17T22:33:11Z","completedAt":"2026-10-17T22:33:16Z","checkSuite":{"workflowRun":{"databaseId":901}}}]}}}}]}},{"number":2,"title":"ABC-102: Draft work","state":"OPEN","isDraft":true,"url":"https://github.com/example/app/pull/2","author":{"login":"alex"},"headRefName":"feature/ABC-102-draft","baseRefName":"main","mergeable":"UNKNOWN","mergeStateStatus":"UNKNOWN","reviewDecision":null,"totalCommentsCount":0,"additions":1,"deletions":0,"changedFiles":1,"headRefOid":"bbb222","createdAt":"2026-10-17T22:30:43Z","updatedAt":"2026-10-17T22:30:43Z","mergedAt":null,"closedAt":null,"mergedBy":null,"autoMergeRequest":null,"labels":{"nodes":[]},"latestReviews":{"nodes":[]},"reviewThreads":{"totalCount":0,"nodes":[]},"commitCount":{"totalCount":1},"lastCommit":{"nodes":[{"commit":{"statusCheckRollup":null}}]}}]}}}
    """#.utf8)

    static let status = Data(#"""
    {"data":{"repository":{"pullRequests":{"nodes":[{"number":3,"title":"ABC-103: Broken check","state":"OPEN","isDraft":false,"url":"https://github.com/example/app/pull/3","author":{"login":"alex"},"mergeable":"MERGEABLE","mergeStateStatus":"UNSTABLE","reviewDecision":null,"baseRefName":"main","reviewThreads":{"totalCount":0,"nodes":[]},"lastCommit":{"nodes":[{"commit":{"statusCheckRollup":{"state":"FAILURE","contexts":{"nodes":[{"__typename":"CheckRun","name":"notes","conclusion":"FAILURE","status":"COMPLETED","detailsUrl":"https://github.com/example/app/actions/runs/903/job/9031","startedAt":"2026-10-17T22:33:11Z","completedAt":"2026-10-17T22:33:18Z","checkSuite":{"workflowRun":{"databaseId":903}}}]}}}}]}}]},"ref":{"target":{"statusCheckRollup":{"state":"FAILURE","contexts":{"nodes":[{"__typename":"CheckRun","name":"notes","conclusion":"FAILURE","status":"COMPLETED","detailsUrl":"https://github.com/example/app/actions/runs/903/job/9031","startedAt":"2026-10-17T22:33:11Z","completedAt":"2026-10-17T22:33:18Z","checkSuite":{"workflowRun":{"databaseId":903}}}]}}}}}}}
    """#.utf8)

    static let failedDetails = Data(#"""
    {"data":{"repository":{"pullRequest":{"body":"This pull request fails its check.","url":"https://github.com/example/app/pull/3","reviewThreads":{"nodes":[]},"lastCommit":{"nodes":[{"commit":{"statusCheckRollup":{"state":"FAILURE","contexts":{"nodes":[{"__typename":"CheckRun","databaseId":9031,"name":"notes","conclusion":"FAILURE","status":"COMPLETED","detailsUrl":"https://github.com/example/app/actions/runs/903/job/9031","startedAt":"2026-10-17T22:33:11Z","completedAt":"2026-10-17T22:33:18Z","checkSuite":{"workflowRun":{"databaseId":903}}}]}}}}]}}}}}
    """#.utf8)

    static let threadDetails = Data(#"""
    {"data":{"repository":{"pullRequest":{"body":"Adds the login notes.","url":"https://github.com/example/app/pull/1","reviewThreads":{"nodes":[{"id":"PRRT_thread1","isResolved":false,"path":"notes.txt","line":2,"originalLine":2,"diffSide":"RIGHT","comments":{"nodes":[{"databaseId":4301,"body":"Please rename this line.","author":{"login":"alex"}}]}}]},"lastCommit":{"nodes":[{"commit":{"statusCheckRollup":{"state":"SUCCESS","contexts":{"nodes":[{"__typename":"CheckRun","name":"notes","conclusion":"SUCCESS","status":"COMPLETED","detailsUrl":"https://github.com/example/app/actions/runs/901/job/9011","startedAt":"2026-10-17T22:33:11Z","completedAt":"2026-10-17T22:33:16Z","checkSuite":{"workflowRun":{"databaseId":901}}}]}}}}]}}}}}
    """#.utf8)

    static let files = Data(#"""
    [{"filename":"login.txt","status":"added","additions":1,"deletions":0,"changes":1,"patch":"@@ -0,0 +1 @@\n+login"},{"filename":"notes.txt","status":"modified","additions":2,"deletions":1,"changes":3,"patch":"@@ -1,3 +1,4 @@\n line one\n-line two\n+line two changed\n line three\n+line four"},{"filename":"icon.png","status":"added","additions":0,"deletions":0,"changes":0},{"filename":"new.txt","previous_filename":"old.txt","status":"renamed","additions":0,"deletions":0,"changes":0,"patch":""}]
    """#.utf8)

    static let created = Data(#"""
    {"number":4,"title":"ABC-104: Profile","state":"open","draft":true,"html_url":"https://github.com/example/app/pull/4","user":{"login":"alex"},"head":{"ref":"feature/ABC-104","sha":"ddd444"},"base":{"ref":"main","sha":"eee555"},"created_at":"2026-10-18T08:00:00Z","updated_at":"2026-10-18T08:00:00Z","labels":[]}
    """#.utf8)

    static let labels = Data(#"""
    [{"name":"tech"},{"name":"Feature"},{"name":"bug"}]
    """#.utf8)

    static let myApproval = Data(#"""
    {"data":{"viewer":{"login":"alex"},"repository":{"pullRequest":{"latestReviews":{"nodes":[{"id":"PRR_other","state":"APPROVED","author":{"login":"kim"}},{"id":"PRR_mine","state":"APPROVED","author":{"login":"alex"}}]}}}}}
    """#.utf8)

    static let mutationFailed = Data(#"""
    {"data":{"resolveReviewThread":null},"errors":[{"message":"Could not resolve to a node with the global id of 'x'"}]}
    """#.utf8)

    static let mutationDone = Data(#"""
    {"data":{"resolveReviewThread":{"clientMutationId":null}}}
    """#.utf8)
}
