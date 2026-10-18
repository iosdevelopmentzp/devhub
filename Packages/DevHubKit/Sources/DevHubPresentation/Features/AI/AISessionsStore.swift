import Foundation
import Observation
import DevHubDomain
import DevHubUI

@MainActor
@Observable
final class AISessionsStore {
    enum Scope: String, CaseIterable, Identifiable {
        case project = "This project"
        case all = "All"

        var id: String { rawValue }
    }

    enum ProviderFilter: String, CaseIterable, Identifiable {
        case copilot
        case claude
        case both

        var id: String { rawValue }

        func includes(_ provider: AIProvider) -> Bool {
            switch self {
            case .copilot: provider == .copilot
            case .claude: provider == .claude
            case .both: true
            }
        }
    }

    private(set) var sessions: [AISession] = []
    private(set) var isLoading = false
    private(set) var hasLoaded = false
    var scope: Scope {
        didSet {
            guard scope != oldValue else { return }
            store.set(scope.rawValue, forKey: Self.scopeKey)
        }
    }

    var providerFilter: ProviderFilter {
        didSet {
            guard providerFilter != oldValue else { return }
            store.set(providerFilter.rawValue, forKey: Self.providerKey)
        }
    }

    @ObservationIgnored private let repository: AISessionRepository
    @ObservationIgnored private let session: ProjectSession
    @ObservationIgnored private let store: any KeyValueStore
    @ObservationIgnored private let refreshTask = RefreshTask()

    private static let scopeKey = "claude.scope"
    private static let providerKey = "ai.provider"

    init(repository: AISessionRepository, session: ProjectSession, store: any KeyValueStore) {
        self.repository = repository
        self.session = session
        self.store = store
        let stored = store.string(forKey: Self.scopeKey)
        scope = stored.flatMap(Scope.init(rawValue:)) ?? .project
        providerFilter = store.string(forKey: Self.providerKey).flatMap(ProviderFilter.init(rawValue:)) ?? .both
    }

    var scoped: [AISession] {
        let filtered = sessions.filter { providerFilter.includes($0.provider) }
        guard scope == .project else { return filtered }
        let root = ProjectPath(session.selectedProject.path).expanded
        return filtered.filter { $0.cwd == root || $0.cwd.hasPrefix(root + "/") }
    }

    func refresh() async {
        await refreshTask.run { [weak self] in
            guard let self else { return }
            isLoading = true
            let loaded = await repository.sessions()
            try Task.checkCancellation()
            sessions = loaded
            isLoading = false
            hasLoaded = true
        }
    }
}
