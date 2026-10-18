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
    @ObservationIgnored private let worktrees: any WorktreeLookup
    @ObservationIgnored private let store: any KeyValueStore
    @ObservationIgnored private let refreshTask = RefreshTask()

    private static let scopeKey = "claude.scope"
    private static let providerKey = "ai.provider"

    init(repository: AISessionRepository, session: ProjectSession, worktrees: any WorktreeLookup, store: any KeyValueStore) {
        self.repository = repository
        self.session = session
        self.worktrees = worktrees
        self.store = store
        let stored = store.string(forKey: Self.scopeKey)
        scope = stored.flatMap(Scope.init(rawValue:)) ?? .project
        providerFilter = store.string(forKey: Self.providerKey).flatMap(ProviderFilter.init(rawValue:)) ?? .both
    }

    var scoped: [AISession] {
        let filtered = sessions.filter { providerFilter.includes($0.provider) }
        guard scope == .project else { return filtered }
        let roots = Set(([session.selectedProject.path] + worktrees.worktrees.map(\.path)).map { ProjectPath($0).expanded })
        return filtered.filter { session in
            roots.contains { session.cwd == $0 || session.cwd.hasPrefix($0 + "/") }
        }
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
