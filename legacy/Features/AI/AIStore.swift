import Foundation
import Observation

@MainActor
@Observable
final class AIStore {
    private(set) var sessions: [AISession] = []
    private(set) var error: String?
    private(set) var isLoading = false

    var providerFilter: AIProviderFilter = .both {
        didSet { save(providerFilter.rawValue, for: .aiProviderFilter) }
    }

    var scope: AIScope = .project {
        didSet { save(scope.rawValue, for: .aiScope) }
    }

    @ObservationIgnored private let provider: AISessionProviding
    @ObservationIgnored private let workspace: WorkspaceActing
    @ObservationIgnored private let session: ProjectSession
    @ObservationIgnored private let settings: SettingsStore
    @ObservationIgnored private let preferences: AppPreferences
    @ObservationIgnored private let activity: ActivityLog
    @ObservationIgnored private let toaster: Toaster
    @ObservationIgnored private var isRestoring = true

    init(provider: AISessionProviding, workspace: WorkspaceActing, session: ProjectSession, settings: SettingsStore, preferences: AppPreferences, activity: ActivityLog, toaster: Toaster) {
        self.provider = provider
        self.workspace = workspace
        self.session = session
        self.settings = settings
        self.preferences = preferences
        self.activity = activity
        self.toaster = toaster
        restore()
    }

    func visibleSessions() -> [AISession] {
        sessions.filter { providerFilter.includes($0.provider) && isInScope($0) }
    }

    func groups(matching filter: (AISession) -> Bool) -> [AIDayGroup] {
        AIDayGroup.group(visibleSessions().filter(filter))
    }

    func refresh() async {
        guard isLoading == false else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            sessions = try await provider.sessions()
            error = nil
        } catch {
            self.error = error.localizedDescription
            activity.log("Session list failed", detail: error.localizedDescription, outcome: .failure)
        }
    }

    func resume(_ target: AISession) {
        guard target.folderExists else {
            toaster.show("The folder is missing: \(target.folder)", tint: .red)
            return
        }
        let terminal = settings.terminal
        Task {
            do {
                try await workspace.runInTerminal(command: target.resumeCommand, at: target.cwd, terminal: terminal)
                activity.log("Resume \(target.provider.title) session", detail: target.fullResumeCommand, outcome: .success)
            } catch {
                activity.log("Resume \(target.provider.title) session", detail: error.localizedDescription, outcome: .failure)
                toaster.show("Could not open the terminal.", tint: .red)
            }
        }
    }

    func copyResumeCommand(_ target: AISession) {
        toaster.copy(target.fullResumeCommand, label: "resume command")
    }

    private func isInScope(_ candidate: AISession) -> Bool {
        guard scope == .project, let path = session.project?.path else { return true }
        let root = path.hasSuffix("/") ? String(path.dropLast()) : path
        return candidate.cwd == root || candidate.cwd.hasPrefix(root + "/")
    }

    private func restore() {
        providerFilter = preferences.string(.aiProviderFilter).flatMap(AIProviderFilter.init(rawValue:)) ?? .both
        scope = preferences.string(.aiScope).flatMap(AIScope.init(rawValue:)) ?? .project
        isRestoring = false
    }

    private func save(_ value: String, for key: AppPreferences.Key) {
        guard isRestoring == false else { return }
        preferences.set(value, for: key)
    }
}
