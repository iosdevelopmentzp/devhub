import Foundation
import Observation
import DevHubDomain

@MainActor
@Observable
final class SimulatorQAStore {
    private(set) var busyIDs: Set<Simulator.ID> = []
    private(set) var screenshots: [Simulator.ID: String] = [:]
    private(set) var needsReboot: Set<Simulator.ID> = []
    private(set) var recordingIDs: Set<Simulator.ID> = []
    private(set) var recordingStarts: [Simulator.ID: Date] = [:]
    private(set) var recordings: [Simulator.ID: String] = [:]
    var addsDeviceFrame: Bool {
        didSet { store.set(addsDeviceFrame, forKey: Keys.addsDeviceFrame) }
    }

    @ObservationIgnored private let repository: any SimulatorSettingsRepository
    @ObservationIgnored private let media: any MediaRepository
    @ObservationIgnored private let store: any KeyValueStore
    @ObservationIgnored private let activity: ActivityLog
    @ObservationIgnored private let operations: OperationLog
    @ObservationIgnored private let screenshotFolder: String
    @ObservationIgnored private let now: () -> Date
    @ObservationIgnored private var recordingTasks: [Simulator.ID: Task<Void, Never>] = [:]

    init(repository: any SimulatorSettingsRepository, media: any MediaRepository, store: any KeyValueStore, activity: ActivityLog, operations: OperationLog, screenshotFolder: String, now: @escaping () -> Date) {
        self.repository = repository
        self.media = media
        self.store = store
        self.activity = activity
        self.operations = operations
        self.screenshotFolder = screenshotFolder
        self.now = now
        addsDeviceFrame = store.bool(forKey: Keys.addsDeviceFrame)
    }

    func isBusy(_ id: Simulator.ID) -> Bool {
        busyIDs.contains(id)
    }

    func isRecording(_ id: Simulator.ID) -> Bool {
        recordingIDs.contains(id)
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
        guard busyIDs.contains(simulator.id) == false else { return }
        busyIDs.insert(simulator.id)
        let path = ProjectPath(screenshotFolder).expanded + "/" + SimulatorQAText.screenshotName(simulator: simulator.name, date: now())
        let framed = addsDeviceFrame
        let repository = repository
        let media = media
        Task { [weak self] in
            guard let self else { return }
            let title = "Screenshot of \(simulator.name)"
            do {
                try await repository.screenshot(udid: simulator.id, to: path, cutsCorners: framed)
                screenshots[simulator.id] = path
                if framed {
                    do {
                        try await media.addFrame(to: path, udid: simulator.id)
                        activity.log(title, detail: "With the device frame", outcome: .success)
                    } catch {
                        activity.log("\(title) has no frame", detail: error.localizedDescription, outcome: .failure)
                    }
                } else {
                    activity.log(title, detail: "", outcome: .success)
                }
            } catch {
                activity.log("\(title) failed", detail: error.localizedDescription, outcome: .failure)
            }
            busyIDs.remove(simulator.id)
        }
    }

    func startRecording(_ simulator: Simulator) {
        guard recordingIDs.contains(simulator.id) == false else { return }
        let path = ProjectPath(screenshotFolder).expanded + "/" + SimulatorQAText.recordingName(simulator: simulator.name, date: now())
        recordingIDs.insert(simulator.id)
        let operationID = operations.start(
            "Recording \(simulator.name)",
            at: .simulator(simulator.id),
            retry: nil,
            stop: { [weak self] in
                guard let self else { return }
                stopRecording(simulator.id)
            }
        )
        let repository = repository
        recordingTasks[simulator.id] = Task { [weak self] in
            guard let self else { return }
            var failure: (any Error)?
            do {
                try await OperationScope.$current.withValue(operationID) {
                    try await repository.record(udid: simulator.id, to: path) { [weak self] in
                        Task { @MainActor [weak self] in
                            guard let self else { return }
                            markStarted(simulator.id)
                        }
                    }
                }
            } catch {
                failure = error
            }
            finishRecording(simulator, path: path, operationID: operationID, failure: failure)
        }
    }

    func stopRecording(_ id: Simulator.ID) {
        recordingTasks[id]?.cancel()
    }

    func stopAllRecordings() {
        recordingTasks.values.forEach { $0.cancel() }
    }

    func rebooted(_ id: Simulator.ID) {
        needsReboot.remove(id)
    }

    private func markStarted(_ id: Simulator.ID) {
        guard recordingIDs.contains(id) else { return }
        recordingStarts[id] = now()
    }

    private func finishRecording(_ simulator: Simulator, path: String, operationID: OperationRecord.ID, failure: (any Error)?) {
        recordingIDs.remove(simulator.id)
        recordingStarts[simulator.id] = nil
        recordingTasks[simulator.id] = nil
        guard let failure else {
            recordings[simulator.id] = path
            operations.succeed(operationID)
            activity.log("Recorded \(simulator.name)", detail: (path as NSString).lastPathComponent, outcome: .success)
            return
        }
        operations.fail(operationID, message: failure.localizedDescription)
        activity.log("Recording of \(simulator.name) failed", detail: failure.localizedDescription, outcome: .failure)
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

    private enum Keys {
        static let addsDeviceFrame = "simulatorQA.addsDeviceFrame"
    }
}
