import Foundation
import Observation
import DevHubDomain

@MainActor
@Observable
final class UpdateStore {
    enum State: Equatable {
        case idle
        case available([UpdateCommit])
        case running(UpdatePhase, startedAt: Date)
        case failed(message: String)
    }

    private(set) var state: State = .idle
    private(set) var installed: InstalledBuild?
    private(set) var log: String?
    private(set) var isChecking = false

    @ObservationIgnored var onInstalling: (() -> Void)?

    @ObservationIgnored private let repository: any UpdateRepository
    @ObservationIgnored private let toaster: Toaster
    @ObservationIgnored private let activity: ActivityLog
    @ObservationIgnored private let checkInterval: Duration
    @ObservationIgnored private let statusInterval: Duration
    @ObservationIgnored private let now: () -> Date
    @ObservationIgnored private var checkTask: Task<Void, Never>?
    @ObservationIgnored private var statusTask: Task<Void, Never>?
    @ObservationIgnored private var didAskToQuit = false

    static let livenessPollCount = 3

    init(repository: any UpdateRepository, toaster: Toaster, activity: ActivityLog, checkInterval: Duration, statusInterval: Duration, now: @escaping () -> Date) {
        self.repository = repository
        self.toaster = toaster
        self.activity = activity
        self.checkInterval = checkInterval
        self.statusInterval = statusInterval
        self.now = now
    }

    var isInstalledBuild: Bool {
        installed != nil
    }

    func start() {
        Task { await load() }
    }

    func load() async {
        do {
            installed = try await repository.installed()
        } catch {
            activity.log("Cannot read the installed build", detail: error.localizedDescription, outcome: .failure)
            return
        }
        guard let installed else { return }
        await settleAfterLaunch(installed)
        startChecking()
    }

    func checkNow() async {
        guard let installed else {
            toaster.show("Updates need an installed build (Scripts/install.sh)")
            return
        }
        await check(installed, reporting: true)
    }

    func update() async {
        guard let installed else { return }
        if case .running = state { return }
        do {
            try await repository.start(installed: installed)
        } catch {
            state = .failed(message: error.localizedDescription)
            activity.log("Update could not start", detail: error.localizedDescription, outcome: .failure)
            return
        }
        didAskToQuit = false
        log = nil
        state = .running(.fetching, startedAt: now())
        activity.log("Update started", detail: "Getting the changes of \(installed.remoteBranch), then building and installing", outcome: .info)
        startStatusPolling()
    }

    func loadLog() async {
        log = try? await repository.log()
    }

    private func settleAfterLaunch(_ installed: InstalledBuild) async {
        let status = try? await repository.status()
        let isRunning = await repository.isUpdateRunning()
        switch UpdateLaunchPolicy.outcome(status: status, installed: installed, isUpdateRunning: isRunning) {
        case .nothing:
            break
        case .clearStatus:
            try? await repository.clearStatus()
        case .updated:
            toaster.show("Updated to \(installed.shortCommit)")
            activity.log("Updated to \(installed.shortCommit)", detail: "DevHub now runs the build of \(installed.commit)", outcome: .success)
            try? await repository.clearStatus()
        case .failed(let message):
            await fail(message)
        case .running(let status):
            state = .running(status.phase, startedAt: status.startedAt)
            startStatusPolling()
        case .stopped:
            await fail(UpdateLaunchPolicy.stoppedMessage)
            try? await repository.clearStatus()
        }
    }

    private func startChecking() {
        guard checkTask == nil else { return }
        checkTask = Task { [weak self] in
            guard let self else { return }
            while Task.isCancelled == false {
                if let installed {
                    await check(installed, reporting: false)
                }
                try? await Task.sleep(for: checkInterval)
            }
        }
    }

    private func check(_ installed: InstalledBuild, reporting: Bool) async {
        switch state {
        case .running, .failed:
            if reporting { toaster.show(state.isRunning ? "An update is running" : "The last update failed. Try again from the footer") }
            return
        case .idle, .available:
            break
        }
        isChecking = true
        defer { isChecking = false }
        do {
            let result = try await repository.check(installed: installed)
            apply(result, installed: installed, reporting: reporting)
        } catch {
            activity.log("Update check failed", detail: error.localizedDescription, outcome: .failure)
            if reporting { toaster.show("Update check failed: \(error.localizedDescription)") }
        }
    }

    private func apply(_ result: UpdateCheck, installed: InstalledBuild, reporting: Bool) {
        switch result {
        case .available(let commits):
            if state != .available(commits) {
                state = .available(commits)
                activity.log("Update available", detail: "\(commits.count) new commits on \(installed.remoteBranch)", outcome: .info)
            }
            if reporting { toaster.show("Update available · \(commits.count)") }
        case .upToDate:
            state = .idle
            if reporting { toaster.show("DevHub is up to date (\(installed.shortCommit))") }
        case .unknownInstalledCommit:
            state = .idle
            if reporting { toaster.show("The installed build \(installed.shortCommit) is not on \(installed.remoteBranch)") }
        }
    }

    private func startStatusPolling() {
        statusTask?.cancel()
        statusTask = Task { [weak self] in
            guard let self else { return }
            var polls = 0
            while Task.isCancelled == false {
                try? await Task.sleep(for: statusInterval)
                guard Task.isCancelled == false else { return }
                polls += 1
                guard await pollStatus(checkLiveness: polls >= Self.livenessPollCount) else { return }
            }
        }
    }

    private func pollStatus(checkLiveness: Bool) async -> Bool {
        guard let status = try? await repository.status() else {
            state = .idle
            return false
        }
        switch status.phase {
        case .fetching, .building, .installing:
            if checkLiveness, await repository.isUpdateRunning() == false {
                await fail(UpdateLaunchPolicy.stoppedMessage)
                try? await repository.clearStatus()
                return false
            }
            state = .running(status.phase, startedAt: status.startedAt)
            if status.phase == .installing, didAskToQuit == false {
                didAskToQuit = true
                onInstalling?()
            }
            return true
        case .done:
            state = .idle
            installed = (try? await repository.installed()) ?? installed
            try? await repository.clearStatus()
            if let installed { toaster.show("Updated to \(installed.shortCommit)") }
            return false
        case .failed:
            await fail(status.message ?? UpdateLaunchPolicy.noMessage)
            return false
        }
    }

    #if DEBUG
    func debugSet(_ state: State, installed: InstalledBuild, log: String?) {
        self.installed = installed
        self.log = log
        self.state = state
    }
    #endif

    private func fail(_ message: String) async {
        state = .failed(message: message)
        await loadLog()
        activity.log("Update failed", detail: message, outcome: .failure)
    }
}

extension UpdateStore.State {
    var isRunning: Bool {
        if case .running = self { return true }
        return false
    }
}
