import Foundation

package struct PullRequestFilter: Hashable, Codable, Sendable {
    package var targetBranch: String? = nil
    package var labels: [String] = []
    package var author: String? = nil
    package var assignee: String? = nil
    package var reviewer: String? = nil
    package var onlyConflicts = false
    package var onlyReady = false

    package init(
        targetBranch: String? = nil,
        labels: [String] = [],
        author: String? = nil,
        assignee: String? = nil,
        reviewer: String? = nil,
        onlyConflicts: Bool = false,
        onlyReady: Bool = false
    ) {
        self.targetBranch = targetBranch
        self.labels = labels
        self.author = author
        self.assignee = assignee
        self.reviewer = reviewer
        self.onlyConflicts = onlyConflicts
        self.onlyReady = onlyReady
    }

    package init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        targetBranch = try container.decodeIfPresent(String.self, forKey: .targetBranch)
        let single = try container.decodeIfPresent(String.self, forKey: .label)
        labels = try container.decodeIfPresent([String].self, forKey: .labels) ?? single.map { [$0] } ?? []
        author = try container.decodeIfPresent(String.self, forKey: .author)
        assignee = try container.decodeIfPresent(String.self, forKey: .assignee)
        reviewer = try container.decodeIfPresent(String.self, forKey: .reviewer)
        onlyConflicts = try container.decodeIfPresent(Bool.self, forKey: .onlyConflicts) ?? false
        onlyReady = try container.decodeIfPresent(Bool.self, forKey: .onlyReady) ?? false
    }

    package func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(targetBranch, forKey: .targetBranch)
        try container.encode(labels, forKey: .labels)
        try container.encodeIfPresent(author, forKey: .author)
        try container.encodeIfPresent(assignee, forKey: .assignee)
        try container.encodeIfPresent(reviewer, forKey: .reviewer)
        try container.encode(onlyConflicts, forKey: .onlyConflicts)
        try container.encode(onlyReady, forKey: .onlyReady)
    }

    package var isActive: Bool {
        self != PullRequestFilter()
    }

    package mutating func toggleLabel(_ label: String) {
        if let index = labels.firstIndex(of: label) {
            labels.remove(at: index)
        } else {
            labels.append(label)
        }
    }

    private enum CodingKeys: String, CodingKey {
        case targetBranch, label, labels, author, assignee, reviewer, onlyConflicts, onlyReady
    }
}
