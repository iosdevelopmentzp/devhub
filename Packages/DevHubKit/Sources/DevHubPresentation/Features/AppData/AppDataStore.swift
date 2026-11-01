import Foundation
import Observation
import DevHubDomain

@MainActor
@Observable
final class AppDataStore {
    private(set) var data: [Simulator.ID: AppData] = [:]
    private(set) var loadingIDs: Set<Simulator.ID> = []
    private(set) var busyIDs: Set<Simulator.ID> = []
    private(set) var errors: [Simulator.ID: String] = [:]

    @ObservationIgnored private let repository: any AppDataRepository
    @ObservationIgnored private let operations: OperationLog
    @ObservationIgnored private let activity: ActivityLog
    @ObservationIgnored private let refreshTask = RefreshTask()

    init(repository: any AppDataRepository, operations: OperationLog, activity: ActivityLog) {
        self.repository = repository
        self.operations = operations
        self.activity = activity
    }

    func isBusy(_ id: Simulator.ID) -> Bool {
        busyIDs.contains(id) || loadingIDs.contains(id)
    }

    func load(simulatorID: Simulator.ID, bundleID: String) async {
        guard bundleID.isEmpty == false else { return }
        loadingIDs.insert(simulatorID)
        await refreshTask.run { [weak self] in
            guard let self else { return }
            let result: Result<AppData, any Error>
            do {
                result = .success(try await repository.read(udid: simulatorID, bundleID: bundleID))
            } catch {
                result = .failure(error)
            }
            try Task.checkCancellation()
            apply(result, simulatorID: simulatorID, bundleID: bundleID)
        }
        loadingIDs.remove(simulatorID)
    }

    func forget(simulatorID: Simulator.ID) {
        data[simulatorID] = nil
        errors[simulatorID] = nil
    }

    func write(_ value: AppDefaultValue, key: String, in suite: AppDefaultsSuite, simulatorID: Simulator.ID) {
        run(simulatorID, title: "Set \(key) in \(suite.name)") { [repository] in
            try await repository.write(value, key: key, plistPath: suite.plistPath, udid: simulatorID)
        }
    }

    func delete(key: String, in suite: AppDefaultsSuite, simulatorID: Simulator.ID) {
        run(simulatorID, title: "Delete \(key) from \(suite.name)") { [repository] in
            try await repository.delete(key: key, plistPath: suite.plistPath, udid: simulatorID)
        }
    }

    func reset(simulatorID: Simulator.ID, includingGroups: Bool) {
        guard let current = data[simulatorID] else { return }
        run(simulatorID, title: "Reset app data of \(current.bundleID)") { [repository] in
            try await repository.reset(current, udid: simulatorID, includingGroups: includingGroups)
        }
    }

    private func apply(_ result: Result<AppData, any Error>, simulatorID: Simulator.ID, bundleID: String) {
        switch result {
        case .success(let loaded):
            data[simulatorID] = loaded
            errors[simulatorID] = nil
        case .failure(let error):
            data[simulatorID] = nil
            errors[simulatorID] = error.localizedDescription
            activity.log("Cannot read app data of \(bundleID)", detail: error.localizedDescription, outcome: .failure)
        }
    }

    private func run(_ simulatorID: Simulator.ID, title: String, work: @escaping () async throws -> Void) {
        guard let bundleID = data[simulatorID]?.bundleID, busyIDs.contains(simulatorID) == false else { return }
        busyIDs.insert(simulatorID)
        Task { [weak self] in
            guard let self else { return }
            do {
                try await operations.perform(title, at: .simulator(simulatorID), retry: nil, work: work)
                activity.log(title, detail: bundleID, outcome: .success)
            } catch {
                activity.log("\(title) failed", detail: error.localizedDescription, outcome: .failure)
            }
            busyIDs.remove(simulatorID)
            await load(simulatorID: simulatorID, bundleID: bundleID)
        }
    }
}
