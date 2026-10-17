import Foundation
import DevHubDomain
import DevHubUI

enum BranchChoiceMapper {
    static let limit = 200

    static func choices(local: [GitBranch], remote: [RemoteBranch], remoteName: String, query: String) -> [BranchChoiceModel] {
        let locals = local.map { BranchChoiceModel(name: $0.name, detail: $0.worktreePath != nil ? "local · has a checkout" : "local") }
        let localNames = Set(locals.map(\.name))
        let remotes = remote
            .map { BranchName($0.name, remote: remoteName).local }
            .filter { localNames.contains($0) == false }
            .map { BranchChoiceModel(name: $0, detail: "remote") }
        let all = locals + remotes
        let trimmed = query.trimmed
        let matching = trimmed.isEmpty ? all : all.filter { $0.name.localizedCaseInsensitiveContains(trimmed) }
        return Array(matching.prefix(limit))
    }
}
