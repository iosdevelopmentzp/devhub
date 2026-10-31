import Foundation

enum GhFixture {
    static let list = Data(#"""
    {"data":{"viewer":{"login":"alex"},"repository":{"viewerPermission":"ADMIN","viewerDefaultMergeMethod":"MERGE","deleteBranchOnMerge":false,"autoMergeAllowed":false},"search":{"issueCount":3,"pageInfo":{"hasNextPage":false,"endCursor":"Y3Vyc29yOjM="},"nodes":[{"number":3,"title":"ABC-103: Broken check","state":"OPEN","isDraft":false,"url":"https://github.com/example/app/pull/3","author":{"login":"alex"},"headRefName":"feature/ABC-103-broken","baseRefName":"main","mergeable":"MERGEABLE","mergeStateStatus":"UNSTABLE","reviewDecision":null,"totalCommentsCount":0,"additions":1,"deletions":0,"changedFiles":1,"headRefOid":"ccc333","createdAt":"2026-10-17T22:33:04Z","updatedAt":"2026-10-17T22:33:04Z","mergedAt":null,"closedAt":null,"mergedBy":null,"autoMergeRequest":null,"labels":{"nodes":[]},"latestReviews":{"nodes":[{"state":"CHANGES_REQUESTED","author":{"login":"kim"}},{"state":"COMMENTED","author":{"login":"sam"}}]},"reviewThreads":{"totalCount":0,"nodes":[]},"commitCount":{"totalCount":1},"lastCommit":{"nodes":[{"commit":{"statusCheckRollup":{"state":"FAILURE","contexts":{"nodes":[{"__typename":"CheckRun","name":"notes","conclusion":"FAILURE","status":"COMPLETED","detailsUrl":"https://github.com/example/app/actions/runs/903/job/9031","startedAt":"2026-10-17T22:33:11Z","completedAt":"2026-10-17T22:33:18Z","checkSuite":{"workflowRun":{"databaseId":903}}}]}}}}]}},{"number":1,"title":"ABC-101: Login screen","state":"OPEN","isDraft":false,"url":"https://github.com/example/app/pull/1","author":{"login":"alex"},"headRefName":"feature/ABC-101-login","baseRefName":"main","mergeable":"MERGEABLE","mergeStateStatus":"CLEAN","reviewDecision":null,"totalCommentsCount":2,"comments":{"nodes":[{"databaseId":501,"author":{"login":"sam"}}]},"recentThreads":{"nodes":[{"comments":{"nodes":[{"databaseId":601,"author":{"login":"lee"}},{"databaseId":501,"author":{"login":"sam"}}]}}]},"additions":3,"deletions":1,"changedFiles":2,"headRefOid":"aaa111","createdAt":"2026-10-17T22:30:37Z","updatedAt":"2026-10-17T22:33:02Z","mergedAt":null,"closedAt":null,"mergedBy":null,"autoMergeRequest":null,"labels":{"nodes":[{"name":"feature"}]},"latestReviews":{"nodes":[]},"assignees":{"nodes":[{"login":"sam"}]},"reviewRequests":{"nodes":[{"requestedReviewer":{"login":"kim"}},{"requestedReviewer":{}}]},"reviewThreads":{"totalCount":1,"nodes":[{"isResolved":false}]},"commitCount":{"totalCount":2},"lastCommit":{"nodes":[{"commit":{"statusCheckRollup":{"state":"SUCCESS","contexts":{"nodes":[{"__typename":"CheckRun","name":"notes","conclusion":"SUCCESS","status":"COMPLETED","detailsUrl":"https://github.com/example/app/actions/runs/901/job/9011","startedAt":"2026-10-17T22:33:11Z","completedAt":"2026-10-17T22:33:16Z","checkSuite":{"workflowRun":{"databaseId":901}}}]}}}}]}},{"number":2,"title":"ABC-102: Draft work","state":"OPEN","isDraft":true,"url":"https://github.com/example/app/pull/2","author":{"login":"alex"},"headRefName":"feature/ABC-102-draft","baseRefName":"main","mergeable":"UNKNOWN","mergeStateStatus":"UNKNOWN","reviewDecision":null,"totalCommentsCount":0,"additions":1,"deletions":0,"changedFiles":1,"headRefOid":"bbb222","createdAt":"2026-10-17T22:30:43Z","updatedAt":"2026-10-17T22:30:43Z","mergedAt":null,"closedAt":null,"mergedBy":null,"autoMergeRequest":null,"labels":{"nodes":[]},"latestReviews":{"nodes":[]},"reviewThreads":{"totalCount":0,"nodes":[]},"commitCount":{"totalCount":1},"lastCommit":{"nodes":[{"commit":{"statusCheckRollup":null}}]}}]}}}
    """#.utf8)

    static let status = Data(#"""
    {"data":{"repository":{"pullRequests":{"nodes":[{"number":3,"title":"ABC-103: Broken check","state":"OPEN","isDraft":false,"url":"https://github.com/example/app/pull/3","author":{"login":"alex"},"mergeable":"MERGEABLE","mergeStateStatus":"UNSTABLE","reviewDecision":null,"baseRefName":"main","reviewThreads":{"totalCount":0,"nodes":[]},"lastCommit":{"nodes":[{"commit":{"statusCheckRollup":{"state":"FAILURE","contexts":{"nodes":[{"__typename":"CheckRun","name":"notes","conclusion":"FAILURE","status":"COMPLETED","detailsUrl":"https://github.com/example/app/actions/runs/903/job/9031","startedAt":"2026-10-17T22:33:11Z","completedAt":"2026-10-17T22:33:18Z","checkSuite":{"workflowRun":{"databaseId":903}}}]}}}}]}}]},"ref":{"target":{"statusCheckRollup":{"state":"FAILURE","contexts":{"nodes":[{"__typename":"CheckRun","name":"notes","conclusion":"FAILURE","status":"COMPLETED","detailsUrl":"https://github.com/example/app/actions/runs/903/job/9031","startedAt":"2026-10-17T22:33:11Z","completedAt":"2026-10-17T22:33:18Z","checkSuite":{"workflowRun":{"databaseId":903}}}]}}}}}}}
    """#.utf8)

    static let failedDetails = Data(#"""
    {"data":{"repository":{"pullRequest":{"body":"This pull request fails its check.","url":"https://github.com/example/app/pull/3","reviewThreads":{"nodes":[]},"lastCommit":{"nodes":[{"commit":{"statusCheckRollup":{"state":"FAILURE","contexts":{"nodes":[{"__typename":"CheckRun","databaseId":9031,"name":"notes","title":"Process completed with exit code 1.","conclusion":"FAILURE","status":"COMPLETED","detailsUrl":"https://github.com/example/app/actions/runs/903/job/9031","startedAt":"2026-10-17T22:33:11Z","completedAt":"2026-10-17T22:33:18Z","checkSuite":{"workflowRun":{"databaseId":903,"workflow":{"name":"Check"}}}}]}}}}]}}}}}
    """#.utf8)

    static let circleCIDetails = Data(#"""
    {"data":{"repository":{"pullRequest":{"body":"Runs on CircleCI.","url":"https://github.com/example/app/pull/4","reviewThreads":{"nodes":[]},"lastCommit":{"nodes":[{"commit":{"statusCheckRollup":{"state":"FAILURE","contexts":{"nodes":[{"__typename":"StatusContext","context":"ci/circleci: unit-tests","state":"FAILURE","targetUrl":"https://app.circleci.example.com/pipelines/github/example/app/42/workflows/11111111-2222-3333-4444-555555555555/jobs/7?utm_campaign=vcs-integration-link"},{"__typename":"CheckRun","databaseId":9041,"name":"build-and-test - 1a2b3c4d","conclusion":"FAILURE","status":"COMPLETED","detailsUrl":"https://app.circleci.example.com/pipelines/circleci/ABCDEFGH1234567890abcdef/XYZ0123456789abcdefghij/42/workflows/11111111-2222-3333-4444-555555555555","startedAt":"2026-10-30T10:00:00Z","completedAt":"2026-10-30T10:12:30Z","checkSuite":{"workflowRun":null}},{"__typename":"CheckRun","name":"notes","conclusion":"SUCCESS","status":"COMPLETED","detailsUrl":"https://github.com/example/app/actions/runs/904/job/9042","checkSuite":{"workflowRun":{"databaseId":904,"workflow":{"name":"Check"}}}}]}}}}]}}}}}
    """#.utf8)

    static let threadDetails = Data(#"""
    {"data":{"repository":{"pullRequest":{"body":"Adds the login notes.","url":"https://github.com/example/app/pull/1","reviewThreads":{"nodes":[{"id":"PRRT_thread1","isResolved":false,"path":"notes.txt","line":2,"originalLine":2,"diffSide":"RIGHT","comments":{"nodes":[{"databaseId":4301,"body":"Please rename this line.","author":{"login":"alex"},"createdAt":"2026-10-17T22:41:40Z"},{"databaseId":4302,"body":"Done.","author":{"login":"sam"},"createdAt":"2026-10-17T22:41:47Z"}]}}]},"lastCommit":{"nodes":[{"commit":{"statusCheckRollup":{"state":"SUCCESS","contexts":{"nodes":[{"__typename":"CheckRun","name":"notes","conclusion":"SUCCESS","status":"COMPLETED","detailsUrl":"https://github.com/example/app/actions/runs/901/job/9011","startedAt":"2026-10-17T22:33:11Z","completedAt":"2026-10-17T22:33:16Z","checkSuite":{"workflowRun":{"databaseId":901}}}]}}}}]}}}}}
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

    static let notifications = Data(#"""
    [{"id":"901","unread":true,"reason":"mention","updated_at":"2026-10-30T10:00:00Z","subject":{"title":"ABC-123: Login screen","url":"https://api.github.com/repos/example/app/pulls/12","latest_comment_url":"https://api.github.com/repos/example/app/issues/comments/501","type":"PullRequest"},"repository":{"full_name":"example/app"}},{"id":"902","unread":true,"reason":"review_requested","updated_at":"2026-10-30T09:00:00Z","subject":{"title":"ABC-120: Profile badges","url":"https://api.github.com/repos/example/app/pulls/9","latest_comment_url":"https://api.github.com/repos/example/app/pulls/9","type":"PullRequest"},"repository":{"full_name":"Example/App"}},{"id":"903","unread":true,"reason":"assign","updated_at":"2026-10-29T09:00:00Z","subject":{"title":"Crash on cold start","url":"https://api.github.com/repos/example/app/issues/31","latest_comment_url":null,"type":"Issue"},"repository":{"full_name":"example/app"}},{"id":"904","unread":false,"reason":"comment","updated_at":"2026-10-29T09:00:00Z","subject":{"title":"Old","url":"https://api.github.com/repos/example/app/pulls/2","latest_comment_url":"https://api.github.com/repos/example/app/issues/comments/400","type":"PullRequest"},"repository":{"full_name":"example/app"}},{"id":"905","unread":true,"reason":"mention","updated_at":"2026-10-29T09:00:00Z","subject":{"title":"Other repo","url":"https://api.github.com/repos/example/other/pulls/3","latest_comment_url":null,"type":"PullRequest"},"repository":{"full_name":"example/other"}}]
    """#.utf8)

    static let comment = Data(#"""
    {"id":501,"user":{"login":"sam"},"html_url":"https://github.com/example/app/pull/12#issuecomment-501","body":"@alex can you check the retry path?"}
    """#.utf8)
}
