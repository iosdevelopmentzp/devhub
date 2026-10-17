import Foundation

nonisolated struct AISession: Identifiable, Hashable, Sendable {
    enum Provider: String, Hashable, Sendable {
        case copilot
        case claude

        var title: String {
            switch self {
            case .copilot: "Copilot"
            case .claude: "Claude"
            }
        }

        var executable: String { rawValue }

        var sortOrder: Int {
            switch self {
            case .copilot: 0
            case .claude: 1
            }
        }
    }

    let id: String
    var provider: Provider
    var title: String
    var date: Date
    var folder: String
    var branch: String?
    var lastPrompt: String
    var cwd: String
    var folderExists: Bool

    init(id: String, provider: Provider, title: String, date: Date, folder: String, branch: String?, lastPrompt: String, cwd: String? = nil, folderExists: Bool = true) {
        self.id = id
        self.provider = provider
        self.title = title
        self.date = date
        self.folder = folder
        self.branch = branch
        self.lastPrompt = lastPrompt
        self.cwd = cwd ?? folder
        self.folderExists = folderExists
    }

    var key: String { "\(provider.rawValue):\(id)" }

    var resumeCommand: String { "\(provider.executable) --resume \(id)" }

    var fullResumeCommand: String { "cd \(cwd) && \(resumeCommand)" }
}
