import Foundation
import DevHubDomain

struct MergedBranchesQuery: Sendable {
    let git: GitCommandRunner

    func branches(mergedInto base: String, in directory: String) async -> Set<String> {
        guard let output = try? await git.run(["branch", "--merged", base, "--format=%(refname:short)"], in: directory) else { return [] }
        return Set(output.split(separator: "\n").map { String($0).trimmed })
    }
}
