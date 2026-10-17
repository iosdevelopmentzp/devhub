import Foundation

nonisolated struct Placement: Hashable, Codable, Sendable {
    let rawValue: String

    init(_ rawValue: String) {
        self.rawValue = rawValue
    }

    init(from decoder: Decoder) throws {
        rawValue = try decoder.singleValueContainer().decode(String.self)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }

    static let homeQuickActions = Placement("home.quickActions")
    static let homeScripts = Placement("home.scripts")
    static let gitPills = Placement("git.pills")
    static let gitBranchRow = Placement("git.branchRow")
    static let worktreesRow = Placement("worktrees.row")
    static let simulatorsRunBar = Placement("simulators.runBar")
    static let simulatorsRow = Placement("simulators.row")
    static let logsToolbar = Placement("logs.toolbar")
    static let palette = Placement("palette")

    static func tab(_ id: String) -> Placement {
        Placement("tab.\(id)")
    }
}

nonisolated enum RefreshTarget: String, Codable, Hashable, Sendable {
    case git
    case worktrees
    case simulators
    case scripts
    case logs
}

nonisolated enum ActionRun: Hashable, Sendable, Codable {
    case script(String)
    case command([String])
    case terminal(String)
    case open(String)

    private enum CodingKeys: String, CodingKey {
        case script, command, terminal, open
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let value = try container.decodeIfPresent(String.self, forKey: .script) {
            self = .script(value)
        } else if let value = try container.decodeIfPresent([String].self, forKey: .command) {
            self = .command(value)
        } else if let value = try container.decodeIfPresent(String.self, forKey: .terminal) {
            self = .terminal(value)
        } else if let value = try container.decodeIfPresent(String.self, forKey: .open) {
            self = .open(value)
        } else {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "run needs one of script, command, terminal or open.")
            )
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case let .script(value): try container.encode(value, forKey: .script)
        case let .command(value): try container.encode(value, forKey: .command)
        case let .terminal(value): try container.encode(value, forKey: .terminal)
        case let .open(value): try container.encode(value, forKey: .open)
        }
    }
}

nonisolated struct ActionCondition: Codable, Hashable, Sendable {
    var git: String?
    var simulator: String?
    var tool: String?
    var kind: ProjectKind?
}

nonisolated struct ActionConfig: Codable, Hashable, Sendable {
    var id: String
    var title: String
    var subtitle: String?
    var icon: String?
    var tint: Tint?
    var placements: [Placement]?
    var run: ActionRun
    var cwd: String?
    var inputs: [ActionInput]?
    var confirm: String?
    var refresh: [RefreshTarget]?
    var when: ActionCondition?

    var effectivePlacements: [Placement] {
        placements ?? [.homeScripts]
    }

    func isPlaced(at placement: Placement) -> Bool {
        placement == .palette || effectivePlacements.contains(placement)
    }
}

nonisolated enum InputType: String, Codable, Hashable, Sendable {
    case text
    case number
    case toggle
    case choice
    case branch
    case worktree
    case simulator
    case scheme
    case file
    case folder
}

nonisolated struct InputOption: Codable, Hashable, Sendable {
    var value: String
    var title: String?

    var label: String { title ?? value }
}

nonisolated struct ActionInput: Hashable, Sendable, Codable, Identifiable {
    var key: String
    var title: String
    var type: InputType
    var options: [InputOption]?
    var defaultValue: String?
    var remember: Bool?
    var placeholder: String?

    var id: String { key }

    private enum CodingKeys: String, CodingKey {
        case key, title, type, options, remember, placeholder
        case defaultValue = "default"
    }

    init(key: String, title: String, type: InputType, options: [InputOption]?, defaultValue: String?, remember: Bool?, placeholder: String?) {
        self.key = key
        self.title = title
        self.type = type
        self.options = options
        self.defaultValue = defaultValue
        self.remember = remember
        self.placeholder = placeholder
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        key = try container.decode(String.self, forKey: .key)
        title = try container.decodeIfPresent(String.self, forKey: .title) ?? key
        type = try container.decode(InputType.self, forKey: .type)
        options = try container.decodeIfPresent([InputOption].self, forKey: .options)
        defaultValue = try container.decodeFlexibleString(forKey: .defaultValue)
        remember = try container.decodeIfPresent(Bool.self, forKey: .remember)
        placeholder = try container.decodeIfPresent(String.self, forKey: .placeholder)
    }
}

nonisolated struct TabConfig: Codable, Hashable, Sendable, Identifiable {
    var id: String
    var title: String
    var icon: String?
    var searchPrompt: String?
    var sections: [TabSection]?
}

nonisolated struct TabSection: Codable, Hashable, Sendable {
    var title: String
    var actions: [String]?
    var source: TabSource?
}

nonisolated struct TabSource: Codable, Hashable, Sendable {
    var script: String
    var refresh: String?

    private enum CodingKeys: String, CodingKey {
        case script, refresh
    }

    init(script: String, refresh: String?) {
        self.script = script
        self.refresh = refresh
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        script = try container.decode(String.self, forKey: .script)
        refresh = try container.decodeFlexibleString(forKey: .refresh)
    }
}
