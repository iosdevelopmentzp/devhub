#if DEBUG
import Foundation
import DevHubDomain

extension UpdateStore {
    func debugApply(_ rawValue: String) {
        let sample = InstalledBuild(commit: "0123456789abcdef0123456789abcdef01234567", branch: "main", source: "/Users/alex/Library/Application Support/Example App/source", installedAt: .now)
        switch rawValue {
        case "available":
            debugSet(
                .available([
                    UpdateCommit(hash: "a1b2c3d", subject: "feat(git): stash files and diffs, branch from a stash"),
                    UpdateCommit(hash: "d4e5f6a", subject: "fix(operations): a strip of rows instead of floating cards"),
                    UpdateCommit(hash: "b7c8d9e", subject: "docs: log the step of ADR 013"),
                ]),
                installed: sample,
                log: nil
            )
        case "running":
            debugSet(.running(.building, startedAt: Date.now.addingTimeInterval(-80)), installed: sample, log: nil)
        case "failed":
            debugSet(.failed(message: "The build or the install failed. See update.log"), installed: sample, log: "$ Scripts/install.sh\nlayers: ok\nanonymous: ok\nxcodebuild: error: Build failed\n")
        default:
            break
        }
    }
}
#endif
