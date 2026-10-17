import Foundation

nonisolated struct ProjectConfig: Codable, Hashable, Sendable {
    var name: String?
    var kind: ProjectKind?
    var xcode: XcodeConfig?
    var build: CommandConfig?
    var run: CommandConfig?
    var git: GitConfig?
    var launch: LaunchConfig?
    var logs: LogsConfig?
    var simulators: SimulatorsConfig?
    var home: HomeConfig?

    static let empty = ProjectConfig()
}

nonisolated struct XcodeConfig: Codable, Hashable, Sendable {
    var container: String?
    var scheme: String?
    var configuration: String?
    var bundleID: String?
    var schemes: [String]?
    var bundleIDs: [String: String]?
}

nonisolated struct CommandConfig: Codable, Hashable, Sendable {
    var command: String?
}

nonisolated struct GitConfig: Codable, Hashable, Sendable {
    var baseBranch: String?
    var commitPrefix: CommitPrefixConfig?
    var worktrees: WorktreesConfig?
}

nonisolated struct CommitPrefixConfig: Codable, Hashable, Sendable {
    var pattern: String?
    var format: String?
}

nonisolated struct WorktreesConfig: Codable, Hashable, Sendable {
    var folder: String?
    var include: [String]?
    var bootstrap: String?
    var bootstrapMarker: String?
}

nonisolated struct LaunchConfig: Codable, Hashable, Sendable {
    var profiles: [LaunchProfile]?
}

nonisolated struct LaunchProfile: Codable, Hashable, Sendable, Identifiable {
    var id: String
    var title: String
    var env: [String: String]?
    var args: [String]?
    var defaults: [ProfileDefault]?
    var cleanInstall: Bool?
}

nonisolated struct ProfileDefault: Codable, Hashable, Sendable {
    var suite: String
    var key: String
    var value: String
    var type: String?

    private enum CodingKeys: String, CodingKey {
        case suite, key, value, type
    }

    init(suite: String, key: String, value: String, type: String?) {
        self.suite = suite
        self.key = key
        self.value = value
        self.type = type
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        suite = try container.decode(String.self, forKey: .suite)
        key = try container.decode(String.self, forKey: .key)
        value = try container.decodeFlexibleString(forKey: .value) ?? ""
        type = try container.decodeIfPresent(String.self, forKey: .type)
    }
}

nonisolated struct LogsConfig: Codable, Hashable, Sendable {
    var process: String?
    var subsystem: String?
}

nonisolated struct SimulatorsConfig: Codable, Hashable, Sendable {
    var statusScript: String?
}

nonisolated struct HomeConfig: Codable, Hashable, Sendable {
    var quickActions: [String]?
}

nonisolated extension KeyedDecodingContainer {
    func decodeFlexibleString(forKey key: Key) throws -> String? {
        guard contains(key), try decodeNil(forKey: key) == false else { return nil }
        if let text = try? decode(String.self, forKey: key) {
            return text
        }
        if let flag = try? decode(Bool.self, forKey: key) {
            return flag ? "true" : "false"
        }
        if let number = try? decode(Int.self, forKey: key) {
            return String(number)
        }
        if let number = try? decode(Double.self, forKey: key) {
            return String(number)
        }
        throw DecodingError.typeMismatch(
            String.self,
            DecodingError.Context(codingPath: codingPath + [key], debugDescription: "Expected a string, a number or true or false.")
        )
    }
}
