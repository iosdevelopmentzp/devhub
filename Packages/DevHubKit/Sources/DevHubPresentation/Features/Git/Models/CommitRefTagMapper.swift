import Foundation
import DevHubDomain
import DevHubUI

enum CommitRefTagMapper {

    static func tags(for refs: [GitCommitRef]) -> [TagModel] {
        refs.map(tag(for:))
    }

    private static func tag(for ref: GitCommitRef) -> TagModel {
        switch ref.kind {
        case .head:
            TagModel(ref.name, tint: .blue, systemImage: "location.fill", hint: "HEAD: the commit this checkout is on")
        case .localBranch:
            TagModel(ref.name, tint: .indigo, systemImage: "arrow.triangle.branch", hint: "Local branch")
        case .remoteBranch:
            TagModel(ref.name, tint: .teal, systemImage: "cloud", hint: "Remote branch")
        case .tag:
            TagModel(ref.name, tint: .purple, systemImage: "tag", hint: "Tag")
        }
    }
}
