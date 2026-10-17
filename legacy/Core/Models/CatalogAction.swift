import Foundation

nonisolated enum BuiltinAction: String, CaseIterable, Hashable, Sendable {
    case buildRun
    case runAttach
    case openEditor
    case openFolder
    case terminal
    case copyBranch
    case repository
    case newPullRequest

    var id: String { "builtin.\(rawValue)" }

    var systemImage: String {
        switch self {
        case .buildRun: "play.fill"
        case .runAttach: "ladybug"
        case .openEditor: "hammer"
        case .openFolder: "folder"
        case .terminal: "terminal"
        case .copyBranch: "doc.on.doc"
        case .repository: "safari"
        case .newPullRequest: "arrow.triangle.pull"
        }
    }

    var tint: Tint {
        switch self {
        case .buildRun: .green
        case .runAttach: .orange
        case .openEditor: .indigo
        case .openFolder: .blue
        case .terminal: .purple
        case .copyBranch: .gray
        case .repository: .teal
        case .newPullRequest: .pink
        }
    }

    static func named(_ id: String) -> BuiltinAction? {
        allCases.first { $0.id == id }
    }
}

nonisolated struct CatalogAction: Identifiable, Hashable, Sendable {
    enum Source: Hashable, Sendable {
        case builtin(BuiltinAction)
        case config(ResolvedAction)
    }

    let id: String
    let title: String
    let subtitle: String
    let systemImage: String
    let tint: Tint
    let source: Source

    var origin: ActionOrigin? {
        guard case let .config(resolved) = source else { return nil }
        return resolved.origin
    }

    var inputs: [ActionInput] {
        guard case let .config(resolved) = source else { return [] }
        return resolved.config.inputs ?? []
    }

    var confirm: String? {
        guard case let .config(resolved) = source else { return nil }
        return resolved.config.confirm
    }

    var needsPrompt: Bool {
        inputs.isEmpty == false || confirm != nil
    }

    var isRunnable: Bool {
        guard let origin else { return true }
        return origin.isExecutable
    }

    var blockedHint: String? {
        guard let origin, origin.isExecutable == false else { return nil }
        return "Run chmod +x"
    }

    var fileName: String? {
        origin.map { URL(fileURLWithPath: $0.fileName).lastPathComponent }
    }

    init(builtin: BuiltinAction, title: String, subtitle: String) {
        id = builtin.id
        self.title = title
        self.subtitle = subtitle
        systemImage = builtin.systemImage
        tint = builtin.tint
        source = .builtin(builtin)
    }

    init(resolved: ResolvedAction) {
        let config = resolved.config
        id = config.id
        title = config.title
        subtitle = config.subtitle ?? ""
        systemImage = config.icon ?? "terminal"
        tint = config.tint ?? .gray
        source = .config(resolved)
    }
}
