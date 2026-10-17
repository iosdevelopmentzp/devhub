import Foundation

nonisolated enum AIProviderFilter: String, CaseIterable, Identifiable, Sendable {
    case copilot
    case claude
    case both

    var id: String { rawValue }

    var title: String {
        switch self {
        case .copilot: "Copilot"
        case .claude: "Claude"
        case .both: "Both"
        }
    }

    func includes(_ provider: AISession.Provider) -> Bool {
        switch self {
        case .copilot: provider == .copilot
        case .claude: provider == .claude
        case .both: true
        }
    }
}

nonisolated enum AIScope: String, CaseIterable, Identifiable, Sendable {
    case project
    case all

    var id: String { rawValue }

    var title: String {
        switch self {
        case .project: "This project"
        case .all: "All"
        }
    }
}
