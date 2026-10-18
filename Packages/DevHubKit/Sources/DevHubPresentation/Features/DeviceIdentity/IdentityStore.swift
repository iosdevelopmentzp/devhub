import Foundation
import Observation
import DevHubDomain
import DevHubUI

@MainActor
@Observable
final class IdentityStore: IdentityLookup {
    var apps: [Simulator.ID: InstalledApp] = [:]
    private(set) var reports: [Simulator.ID: AppStateReport] = [:]
    private(set) var settings: [Simulator.ID: SimulatorLaunchSettings] {
        didSet { store.encode(settings, forKey: Self.settingsKey) }
    }
    private(set) var savedDeviceIDs: [String] {
        didSet { store.set(savedDeviceIDs, forKey: Self.savedDeviceIDsKey) }
    }
    private(set) var deviceIDAliases: [String: String] {
        didSet { store.encode(deviceIDAliases, forKey: Self.deviceIDAliasesKey) }
    }
    private(set) var applyingIDs: Set<Simulator.ID> = []

    @ObservationIgnored private let repository: AppLaunchRepository
    @ObservationIgnored private let session: ProjectSession
    @ObservationIgnored private let config: ConfigStore
    @ObservationIgnored private let launchInstalledApp: LaunchInstalledAppUseCase
    @ObservationIgnored private let simulators: any SimulatorLookup
    @ObservationIgnored private let attacher: any XcodeAttaching
    @ObservationIgnored private let activity: ActivityLog
    @ObservationIgnored private let events: AppEvents
    @ObservationIgnored private let store: any KeyValueStore
    @ObservationIgnored private var subscription: SubscriptionToken?

    private static let settingsKey = "simulators.launchSettings"
    private static let savedDeviceIDsKey = "devhub.savedDeviceIDs"
    private static let deviceIDAliasesKey = "devhub.deviceIDAliases"

    init(
        repository: AppLaunchRepository,
        launchInstalledApp: LaunchInstalledAppUseCase,
        session: ProjectSession,
        config: ConfigStore,
        simulators: any SimulatorLookup,
        attacher: any XcodeAttaching,
        activity: ActivityLog,
        events: AppEvents,
        store: any KeyValueStore
    ) {
        self.repository = repository
        self.launchInstalledApp = launchInstalledApp
        self.session = session
        self.config = config
        self.simulators = simulators
        self.attacher = attacher
        self.activity = activity
        self.events = events
        self.store = store
        settings = store.decode([Simulator.ID: SimulatorLaunchSettings].self, forKey: Self.settingsKey) ?? [:]
        savedDeviceIDs = store.strings(forKey: Self.savedDeviceIDsKey) ?? []
        deviceIDAliases = store.decode([String: String].self, forKey: Self.deviceIDAliasesKey) ?? [:]
        subscription = events.subscribe { [weak self] event in
            guard let self else { return }
            switch event {
            case .simulatorsChanged, .configChanged:
                Task { await self.refreshWatched() }
            case .projectChanged:
                apps = [:]
                reports = [:]
            case .buildStarted(let id):
                rememberDesiredDeviceID(for: id)
            case .buildFinished(let id, let launch), .appLaunched(let id, let launch):
                launched(id: id, launch: launch)
            case .appStateReported(let id, let report):
                if reports[id] != report {
                    reports[id] = report
                }
            case .branchesChanged, .worktreesChanged, .commandFailed, .worktreeCheckoutPrepared, .worktreeBootstrapping, .mockSetChanged, .pullRequestsChanged, .refreshRequested:
                break
            }
        }
    }

    var identityConfig: LaunchIdentityConfig? {
        config.config.launch?.identity
    }

    var profiles: [LaunchProfile] {
        config.config.launch?.profiles ?? []
    }

    func bundleID(for id: Simulator.ID) -> String {
        let project = session.selectedProject.bundleID
        let fallback = config.effective(detectedSchemes: [], detectedBaseBranch: nil).bundleID ?? project
        guard let launched = settings(for: id).lastLaunch?.bundleID,
              config.config.knownBundleIDs(detected: project).contains(launched) else { return fallback }
        return launched
    }

    func settings(for id: Simulator.ID) -> SimulatorLaunchSettings {
        settings[id] ?? .empty
    }

    func installedApp(for id: Simulator.ID) -> InstalledApp? {
        apps[id]
    }

    func report(for id: Simulator.ID) -> AppStateReport? {
        reports[id]
    }

    func context(for id: Simulator.ID) -> IdentityContext? {
        guard let identityConfig else { return nil }
        return IdentityContext(
            config: identityConfig,
            profiles: profiles,
            app: apps[id],
            report: reports[id],
            settings: settings(for: id),
            savedDeviceIDs: savedDeviceIDs,
            aliases: deviceIDAliases,
            isApplying: applyingIDs.contains(id)
        )
    }

    func isApplying(_ id: Simulator.ID) -> Bool {
        applyingIDs.contains(id)
    }

    func isInstalled(on id: Simulator.ID) -> Bool {
        apps[id]?.isInstalled == true
    }

    func actualIdentity(for id: Simulator.ID) -> String? {
        reports[id]?.identity ?? settings(for: id).actualIdentity
    }

    // MARK: Reading

    func refresh(id: Simulator.ID) async {
        guard let identityConfig else { return }
        let app = await repository.inspect(udid: id, bundleID: bundleID(for: id), identity: identityConfig, storage: storage)
        guard apps[id] != app else { return }
        apps[id] = app
    }

    private var storage: ProfileStorage? {
        profiles.lazy.compactMap(\.storage).first
    }

    private func refreshWatched() async {
        guard let identityConfig else { return }
        let storage = storage
        let targets = simulators.all
            .filter { $0.state == .booted || $0.isFavorite || (simulators.installedAppCounts[$0.id] ?? 0) > 0 }
            .map { (id: $0.id, bundleID: bundleID(for: $0.id)) }
        await withTaskGroup(of: (Simulator.ID, InstalledApp).self) { group in
            for (id, bundleID) in targets {
                group.addTask { [repository] in
                    (id, await repository.inspect(udid: id, bundleID: bundleID, identity: identityConfig, storage: storage))
                }
            }
            for await (id, app) in group {
                if apps[id] != app {
                    apps[id] = app
                }
            }
        }
    }

    // MARK: Desired values

    func needsCleanInstall(id: Simulator.ID) -> Bool {
        needsCleanInstall(id: id, identity: settings(for: id).desiredIdentity)
    }

    func needsCleanInstall(id: Simulator.ID, identity: String?) -> Bool {
        CleanInstallPolicy.needsCleanInstall(
            app: apps[id],
            report: reports[id],
            settings: settings(for: id),
            desiredIdentity: identity,
            savedIdentities: savedDeviceIDs,
            config: identityConfig
        )
    }

    func setDesiredDeviceID(_ deviceID: String?, for id: Simulator.ID) {
        var current = settings(for: id)
        current.desiredIdentity = deviceID?.trimmed.isEmpty == false ? deviceID?.trimmed : nil
        settings[id] = current
    }

    func newIdentity() -> String {
        (identityConfig ?? LaunchIdentityConfig(variable: "")).newIdentity(uuid: UUID())
    }

    func rememberDesiredDeviceID(for id: Simulator.ID) {
        guard let deviceID = settings(for: id).desiredIdentity, savedDeviceIDs.contains(deviceID) == false else { return }
        savedDeviceIDs.append(deviceID)
    }

    func forgetSavedDeviceID(_ deviceID: String) {
        savedDeviceIDs.removeAll { $0 == deviceID }
        deviceIDAliases[deviceID] = nil
    }

    func alias(for id: Simulator.ID) -> String {
        aliasTarget(for: id).flatMap { deviceIDAliases[$0] } ?? ""
    }

    func setAlias(_ alias: String, for id: Simulator.ID) {
        guard let deviceID = aliasTarget(for: id) else { return }
        guard alias.trimmed.isEmpty == false else {
            deviceIDAliases[deviceID] = nil
            return
        }
        deviceIDAliases[deviceID] = alias
        if settings(for: id).desiredIdentity == deviceID, savedDeviceIDs.contains(deviceID) == false {
            savedDeviceIDs.append(deviceID)
        }
    }

    private func aliasTarget(for id: Simulator.ID) -> String? {
        settings(for: id).desiredIdentity ?? actualIdentity(for: id)
    }

    func plan(for id: Simulator.ID, profile: LaunchProfile?, identity: String?) -> LaunchPlan {
        LaunchPlan(profile: profile, identityConfig: identityConfig, identity: identity, baseURLVariable: config.config.network?.baseURLVariable)
    }

    // MARK: Launch

    func launchInstalledApp(on simulator: Simulator, profile: LaunchProfile?, attachDebugger: Bool, forceCleanInstall: Bool, projectPath: String, fallbackAppPath: String?) {
        if attachDebugger, ensureAccessibility() == false { return }
        let id = simulator.id
        let identity = settings(for: id).desiredIdentity
        let request = IdentityLaunch(
            simulator: simulator,
            bundleID: bundleID(for: id),
            plan: plan(for: id, profile: profile, identity: identity),
            attachDebugger: attachDebugger,
            projectPath: projectPath,
            fallbackAppPath: fallbackAppPath
        )
        rememberDesiredDeviceID(for: id)
        let cleanInstall = forceCleanInstall || profile?.cleanInstall == true || needsCleanInstall(id: id, identity: identity)
        applyingIDs.insert(id)
        Task { [weak self] in
            guard let self else { return }
            var record: LaunchRecord?
            do {
                record = try await launchInstalledApp.execute(request, cleanInstall: cleanInstall)
                let detail = [
                    identity.map { "ID \($0)" } ?? "own ID",
                    profile?.title,
                    cleanInstall ? "clean install" : nil,
                    attachDebugger ? "Xcode attached" : nil
                ]
                .compactMap { $0 }
                .joined(separator: " · ")
                activity.log("Launched on \(simulator.name)", detail: detail, outcome: .success)
            } catch let error as XcodeAttachError {
                record = request.plan.record(bundleID: request.bundleID, baseURL: nil, date: .now)
                logLaunchFailure(error, on: simulator)
            } catch {
                logLaunchFailure(error, on: simulator)
            }
            applyingIDs.remove(id)
            events.post(.appLaunched(simulatorID: id, launch: record))
        }
    }

    private func launched(id: Simulator.ID, launch: LaunchRecord?) {
        if let launch {
            var current = settings(for: id)
            current.appliedIdentity = launch.identity
            current.hasApplied = true
            current.lastLaunch = launch
            settings[id] = current
        }
        Task { [weak self] in
            try? await Task.sleep(for: .seconds(4))
            guard let self else { return }
            await refresh(id: id)
        }
    }

    private func logLaunchFailure(_ error: Error, on simulator: Simulator) {
        activity.log("Could not launch on \(simulator.name)", detail: error.localizedDescription, outcome: .failure)
    }

    private func ensureAccessibility() -> Bool {
        guard attacher.isTrusted == false else { return true }
        attacher.requestTrust()
        activity.log("Allow DevHub in Accessibility", detail: "System Settings → Privacy & Security → Accessibility, then try again", outcome: .failure)
        return false
    }
}
