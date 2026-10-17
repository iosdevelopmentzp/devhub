import Foundation
import DevHubDomain

struct GitLogQuery: Sendable {
    let git: GitCommandRunner

    private static let limit = "150"

    func commits(range: String?, in path: String) async throws -> [GitCommit] {
        let output = try await git.run(["log", "-n", Self.limit, "--decorate=full", "--format=\(GitLogParser.format)"] + (range.map { [$0] } ?? []), in: path)
        let unpushed = GitLogParser.hashes((try? await git.run(["rev-list", "-n", Self.limit, "HEAD", "--not", "--remotes=origin"], in: path)) ?? "")
        return GitLogParser.parse(output, unpushed: unpushed)
    }
}
