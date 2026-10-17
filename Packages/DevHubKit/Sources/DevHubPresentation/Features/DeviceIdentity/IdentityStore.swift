import Foundation
import Observation
import DevHubDomain
import DevHubUI

@MainActor
@Observable
final class IdentityStore: IdentityLookup {
    var identities: [Simulator.ID: AppIdentity] = [:]
    private(set) var settings: [Simulator.ID: SimulatorIdentitySettings] {
        didSet { store.encode(settings, forKey: Self.identityKey) }
    }
    private(set) var savedDeviceIDs: [String] {
        didSet { store.set(savedDeviceIDs, forKey: Self.savedDeviceIDsKey) }
    }
    private(set) var deviceIDAliases: [String: String] {
        didSet { store.encode(deviceIDAliases, forKey: Self.deviceIDAliasesKey) }
    }
    private(set) var applyingIDs: Set<Simulator.ID> = []

    @ObservationIgnored private let repository: DeviceIdentityRepository
    @ObservationIgnored private let session: ProjectSession
    @ObservationIgnored private let launchInstalledApp: LaunchInstalledAppUseCase
    @ObservationIgnored private let simulators: any SimulatorLookup
    @ObservationIgnored private let attacher: any XcodeAttaching
    @ObservationIgnored private let activity: ActivityLog
    @ObservationIgnored private let events: AppEvents
    @ObservationIgnored private let store: any KeyValueStore
    @ObservationIgnored private var subscription: SubscriptionToken?

    private static let identityKey = "simulators.identity"
    private static let savedDeviceIDsKey = "devhub.savedDeviceIDs"
    private static let deviceIDAliasesKey = "devhub.deviceIDAliases"

    init(
        repository: DeviceIdentityRepository,
        launchInstalledApp: LaunchInstalledAppUseCase,
        session: ProjectSession,
        simulators: any SimulatorLookup,
        attacher: any XcodeAttaching,
        activity: ActivityLog,
        events: AppEvents,
        store: any KeyValueStore
    ) {
        self.repository = repository
        self.launchInstalledApp = launchInstalledApp
        self.session = session
        self.simulators = simulators
        self.attacher = attacher
        self.activity = activity
        self.events = events
        self.store = store
        settings = store.decode([Simulator.ID: SimulatorIdentitySettings].self, forKey: Self.identityKey) ?? [:]
        savedDeviceIDs = store.strings(forKey: Self.savedDeviceIDsKey) ?? []
        deviceIDAliases = store.decode([String: String].self, forKey: Self.deviceIDAliasesKey) ?? [:]
        subscription = events.subscribe { [weak self] event in
            guard let self else { return }
            switch event {
            case .simulatorsChanged:
                Task { await self.refreshWatched() }
            case .projectChanged:
                identities = [:]
            case .buildStarted(let id):
                rememberDesiredDeviceID(for: id)
            case .buildFinished(let id, let launchedDeviceID):
                buildFinished(id: id, launchedDeviceID: launchedDeviceID)
            case .branchesChanged, .worktreesChanged, .commandFailed, .appLaunched, .worktreeCheckoutPrepared, .worktreeBootstrapping, .mockSetChanged, .pullRequestsChanged, .configChanged, .refreshRequested:
                break
            }
        }
    }

    var config: DeviceIdentityConfig? {
        session.selectedProject.identity
    }

    func settings(for id: Simulator.ID) -> SimulatorIdentitySettings {
        settings[id] ?? SimulatorIdentitySettings(desiredDeviceID: nil, desiredEnvironment: nil, appliedDeviceID: nil, hasApplied: false)
    }

    func isApplying(_ id: Simulator.ID) -> Bool {
        applyingIDs.contains(id)
    }

    func storedEnvironment(for id: Simulator.ID) -> String? {
        identities[id]?.storedEnvironment
    }

    func isInstalled(on id: Simulator.ID) -> Bool {
        identities[id]?.isInstalled == true
    }

    // MARK: Reading

    func refresh(id: Simulator.ID) async {
        guard let config else { return }
        let identity = await repository.read(udid: id, config: config)
        guard identities[id] != identity else { return }
        identities[id] = identity
    }

    private func refreshWatched() async {
        guard let config else { return }
        let ids = simulators.all
            .filter { $0.state == .booted || $0.isFavorite || (simulators.installedAppCounts[$0.id] ?? 0) > 0 }
            .map(\.id)
        await withTaskGroup(of: (Simulator.ID, AppIdentity).self) { group in
            for id in ids {
                group.addTask { [repository] in
                    (id, await repository.read(udid: id, config: config))
                }
            }
            for await (id, identity) in group {
                if identities[id] != identity {
                    identities[id] = identity
                }
            }
        }
    }

    // MARK: Desired values

    func needsCleanInstall(id: Simulator.ID) -> Bool {
        needsCleanInstall(id: id, deviceID: settings(for: id).desiredDeviceID)
    }

    func needsCleanInstall(id: Simulator.ID, deviceID: String?) -> Bool {
        CleanInstallPolicy.needsCleanInstall(
            identity: identities[id],
            settings: settings(for: id),
            desiredDeviceID: deviceID,
            savedDeviceIDs: savedDeviceIDs
        )
    }

    func setDesiredDeviceID(_ deviceID: String?, for id: Simulator.ID) {
        var current = settings(for: id)
        current.desiredDeviceID = deviceID?.trimmed.isEmpty == false ? deviceID?.trimmed : nil
        settings[id] = current
    }

    func setDesiredEnvironment(_ environment: String?, for id: Simulator.ID) {
        var current = settings(for: id)
        current.desiredEnvironment = environment?.isEmpty == false ? environment : nil
        settings[id] = current
    }

    func rememberDesiredDeviceID(for id: Simulator.ID) {
        guard let deviceID = settings(for: id).desiredDeviceID, savedDeviceIDs.contains(deviceID) == false else { return }
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
        if settings(for: id).desiredDeviceID == deviceID, savedDeviceIDs.contains(deviceID) == false {
            savedDeviceIDs.append(deviceID)
        }
    }

    private func aliasTarget(for id: Simulator.ID) -> String? {
        settings(for: id).desiredDeviceID ?? identities[id]?.lastDeviceID
    }

    func markApplied(id: Simulator.ID, deviceID: String?) {
        var current = settings(for: id)
        current.appliedDeviceID = deviceID
        current.hasApplied = true
        settings[id] = current
    }

    func buildIdentity(for id: Simulator.ID) -> BuildIdentity? {
        guard let config else { return nil }
        let current = settings(for: id)
        return BuildIdentity(config: config, deviceID: current.desiredDeviceID, environment: current.desiredEnvironment)
    }

    // MARK: Launch

    func launchInstalledApp(on simulator: Simulator, attachDebugger: Bool, forceCleanInstall: Bool, projectPath: String, fallbackAppPath: String?) {
        if attachDebugger, ensureAccessibility() == false { return }
        let current = settings(for: simulator.id)
        launch(IdentityLaunch(
            simulator: simulator,
            deviceID: current.desiredDeviceID,
            environment: current.desiredEnvironment,
            forceCleanInstall: forceCleanInstall,
            attachDebugger: attachDebugger,
            projectPath: projectPath,
            fallbackAppPath: fallbackAppPath
        ))
    }

    private func launch(_ request: IdentityLaunch) {
        guard let config else { return }
        let id = request.simulator.id
        rememberDesiredDeviceID(for: id)
        let cleanInstall = request.forceCleanInstall || needsCleanInstall(id: id, deviceID: request.deviceID)
        applyingIDs.insert(id)
        Task { [weak self] in
            guard let self else { return }
            do {
                try await launchInstalledApp.execute(request, config: config, cleanInstall: cleanInstall)
                markApplied(id: id, deviceID: request.deviceID)
                let detail = [
                    request.deviceID.map { "device ID \($0)" } ?? "real device ID",
                    request.environment,
                    cleanInstall ? "clean install" : nil,
                    request.attachDebugger ? "Xcode attached" : nil
                ]
                .compactMap { $0 }
                .joined(separator: " · ")
                activity.log("Launched on \(request.simulator.name)", detail: detail, outcome: .success)
            } catch let error as XcodeAttachError {
                markApplied(id: id, deviceID: request.deviceID)
                logLaunchFailure(error, on: request.simulator)
            } catch {
                logLaunchFailure(error, on: request.simulator)
            }
            applyingIDs.remove(id)
            try? await Task.sleep(for: .seconds(4))
            await refresh(id: id)
            events.post(.appLaunched(simulatorID: id))
        }
    }

    private func buildFinished(id: Simulator.ID, launchedDeviceID: String??) {
        if case .some(let deviceID) = launchedDeviceID {
            markApplied(id: id, deviceID: deviceID)
        }
        Task { [weak self] in
            try? await Task.sleep(for: .seconds(4))
            guard let self else { return }
            await refresh(id: id)
        }
    }

    private func logLaunchFailure(_ error: Error, on simulator: Simulator) {
        activity.log("Could not apply device settings: \(simulator.name)", detail: error.localizedDescription, outcome: .failure)
    }

    private func ensureAccessibility() -> Bool {
        guard attacher.isTrusted == false else { return true }
        attacher.requestTrust()
        activity.log("Allow DevHub in Accessibility", detail: "System Settings → Privacy & Security → Accessibility, then try again", outcome: .failure)
        return false
    }
}
