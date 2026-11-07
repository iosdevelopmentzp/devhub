import Foundation

package enum UpdateCheckPolicy {

    package static func result(installedIsOnRemote: Bool, newCommits: [UpdateCommit]) -> UpdateCheck {
        guard installedIsOnRemote else { return .unknownInstalledCommit }
        guard newCommits.isEmpty == false else { return .upToDate }
        return .available(newCommits)
    }
}
