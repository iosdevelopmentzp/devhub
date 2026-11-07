import Foundation
import DevHubDomain
import DevHubUI

enum PullRequestFileGroupChipMapper {

    static func models(for matches: [FileGroupMatch], groups: [PullRequestFileGroup], toggled: Set<String>) -> [PullRequestFileGroupChipModel] {
        matches.map { match in
            model(for: match, patterns: groups.first { $0.name == match.name }?.patterns ?? [], isHidden: FileGroupPolicy.isHidden(match, toggled: toggled))
        }
    }

    static func model(for match: FileGroupMatch, patterns: [String], isHidden: Bool) -> PullRequestFileGroupChipModel {
        let count = match.paths.count
        let files = CountText.count(count, "file")
        let verb = count == 1 ? "is" : "are"
        let them = count == 1 ? "it" : "them"
        let rule = patterns.isEmpty ? "" : " (\(patterns.joined(separator: ", ")))"
        return PullRequestFileGroupChipModel(
            id: match.name,
            title: "\(match.name) \(count)",
            icon: isHidden ? "eye.slash" : "eye",
            tint: isHidden ? .secondary : .blue,
            isHidden: isHidden,
            hint: "\(files) \(verb) in the group \(match.name)\(rule). Click to \(isHidden ? "show" : "hide") \(them). The groups come from git.pullRequests.fileGroups in project.json."
        )
    }
}
