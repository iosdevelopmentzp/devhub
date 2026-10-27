import Foundation
import Observation
import DevHubDomain

@MainActor
@Observable
final class SimulatorQAStore {
    private(set) var busyIDs: Set<Simulator.ID> = []
    private(set) var screenshots: [Simulator.ID: String] = [:]
    private(set) var needsReboot: Set<Simulator.ID> = []

    @ObservationIgnored private let repository: any SimulatorSettingsRepository
    @ObservationIgnored private let activity: ActivityLog
    @ObservationIgnored private let screenshotFolder: String
    @ObservationIgnored private let now: () -> Date

    init(repository: any SimulatorSettingsRepository, activity: ActivityLog, screenshotFolder: String, now: @escaping () -> Date) {
        self.repository = repository
        self.activity = activity
        self.screenshotFolder = screenshotFolder
        self.now = now
    }

    func isBusy(_ id: Simulator.ID) -> Bool {
        busyIDs.contains(id)
    }

    func apply(_ setting: SimulatorSetting, to simulator: Simulator) {
        let title = SimulatorQAText.logTitle(for: setting, simulator: simulator.name)
        run(simulator.id, title: title) { [repository] in
            try await repository.apply(setting, udid: simulator.id)
        } done: { [weak self] in
            guard let self, case .language = setting else { return }
            needsReboot.insert(simulator.id)
        }
    }

    func screenshot(_ simulator: Simulator) {
        let path = ProjectPath(screenshotFolder).expanded + "/" + SimulatorQAText.screenshotName(simulator: simulator.name, date: now())
        run(simulator.id, title: "Screenshot of \(simulator.name)") { [repository] in
            try await repository.screenshot(udid: simulator.id, to: path)
        } done: { [weak self] in
            self?.screenshots[simulator.id] = path
        }
    }

    func rebooted(_ id: Simulator.ID) {
        needsReboot.remove(id)
    }

    private func run(_ id: Simulator.ID, title: String, work: @escaping @Sendable () async throws -> Void, done: @escaping @MainActor () -> Void) {
        guard busyIDs.contains(id) == false else { return }
        busyIDs.insert(id)
        Task { [weak self] in
            guard let self else { return }
            do {
                try await work()
                activity.log(title, detail: "", outcome: .success)
                done()
            } catch {
                activity.log("\(title) failed", detail: error.localizedDescription, outcome: .failure)
            }
            busyIDs.remove(id)
        }
    }
}
