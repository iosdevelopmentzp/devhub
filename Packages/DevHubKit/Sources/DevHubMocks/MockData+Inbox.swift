import Foundation
import DevHubDomain

extension MockData {
    package static let inboxItems: [InboxItem] = [
        InboxItem(id: "901", kind: .mention, title: "ABC-123: Login screen", actor: "sam", excerpt: "@alex can you check the retry path?", target: .pullRequest(iid: 12), webURL: URL(string: "https://gitlab.com/example/app/-/merge_requests/12#note_901"), updatedAt: ago(minutes: 25)),
        InboxItem(id: "902", kind: .reviewRequested, title: "ABC-120: Profile badges", actor: "kim", excerpt: nil, target: .pullRequest(iid: 9), webURL: URL(string: "https://gitlab.com/example/app/-/merge_requests/9"), updatedAt: ago(hours: 3)),
        InboxItem(id: "903", kind: .assigned, title: "Crash on cold start", actor: "lee", excerpt: nil, target: .issue(iid: 31), webURL: URL(string: "https://gitlab.com/example/app/-/issues/31"), updatedAt: ago(days: 1)),
    ]
}
