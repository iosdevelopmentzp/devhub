import Foundation

package struct CIAutoRerunPlan: Hashable, Sendable, Codable {
    package let iid: Int
    package let maxAttempts: Int
    package var attempts: Int
    package var handledWorkflowIDs: Set<String>
    package var lastRerunAt: Date?
    package var onlyFlaky = true

    private enum CodingKeys: String, CodingKey {
        case iid
        case maxAttempts
        case attempts
        case handledWorkflowIDs
        case lastRerunAt
        case onlyFlaky
    }

    package init(iid: Int, maxAttempts: Int, attempts: Int, handledWorkflowIDs: Set<String>, lastRerunAt: Date?, onlyFlaky: Bool = true) {
        self.iid = iid
        self.maxAttempts = maxAttempts
        self.attempts = attempts
        self.handledWorkflowIDs = handledWorkflowIDs
        self.lastRerunAt = lastRerunAt
        self.onlyFlaky = onlyFlaky
    }

    package init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        iid = try container.decode(Int.self, forKey: .iid)
        maxAttempts = try container.decode(Int.self, forKey: .maxAttempts)
        attempts = try container.decode(Int.self, forKey: .attempts)
        handledWorkflowIDs = try container.decode(Set<String>.self, forKey: .handledWorkflowIDs)
        lastRerunAt = try container.decodeIfPresent(Date.self, forKey: .lastRerunAt)
        onlyFlaky = try container.decodeIfPresent(Bool.self, forKey: .onlyFlaky) ?? true
    }

    package var attemptsLeft: Int {
        max(0, maxAttempts - attempts)
    }
}
