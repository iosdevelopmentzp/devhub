import Foundation
import DevHubDomain

struct CodeHostAccessCheck: Equatable {
    let host: CodeHost
    let result: Result<CodeHostAccess, PullRequestError>
}
