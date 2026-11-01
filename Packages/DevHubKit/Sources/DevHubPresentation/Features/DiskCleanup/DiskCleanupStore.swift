import Foundation
import Observation
import DevHubDomain

@MainActor
@Observable
final class DiskCleanupStore {
    private(set) var items: [DiskCleanupItem] = []
    private(set) var sizes: [DiskCleanupItem.ID: Int64] = [:]
    private(set) var measuringIDs: Set<DiskCleanupItem.ID> = []
    private(set) var busyIDs: Set<DiskCleanupItem.ID> = []
    private(set) var isScanning = false
    private(set) var hasScanned = false
    private(set) var failure: String?

    @ObservationIgnored private let repository: any DiskCleanupRepository
    @ObservationIgnored private let operations: OperationLog
    @ObservationIgnored private let activity: ActivityLog

    static let measureBatch = 4

    init(repository: any DiskCleanupRepository, operations: OperationLog, activity: ActivityLog) {
        self.repository = repository
        self.operations = operations
        self.activity = activity
    }

    func scanIfNeeded() async {
        guard hasScanned == false else { return }
        await scan()
    }

    func scan() async {
        guard isScanning == false else { return }
        isScanning = true
        failure = nil
        do {
            items = try await repository.items()
            sizes = [:]
            hasScanned = true
            await measure()
        } catch {
            failure = error.localizedDescription
            activity.log("Cannot read the disk usage", detail: error.localizedDescription, outcome: .failure)
        }
        isScanning = false
    }

    func clean(_ id: DiskCleanupItem.ID) {
        guard let item = items.first(where: { $0.id == id }), busyIDs.contains(id) == false else { return }
        let title = DiskCleanupText.operationTitle(for: item)
        busyIDs.insert(id)
        Task { [weak self] in
            guard let self else { return }
            do {
                try await operations.perform(title, at: .disk, retry: { [weak self] in
                    guard let self else { return }
                    clean(id)
                }) { [repository] in
                    try await repository.clean(item)
                }
                activity.log(title, detail: DiskCleanupText.command(for: item), outcome: .success)
                items.removeAll { $0.id == id }
                sizes[id] = nil
            } catch {
                activity.log("\(title) failed", detail: error.localizedDescription, outcome: .failure)
            }
            busyIDs.remove(id)
        }
    }

    private func measure() async {
        let pending = items.filter { $0.size == nil }
        measuringIDs = Set(pending.map(\.id))
        let repository = repository
        for start in stride(from: 0, to: pending.count, by: Self.measureBatch) {
            let batch = pending[start ..< min(start + Self.measureBatch, pending.count)]
            await withTaskGroup(of: (DiskCleanupItem.ID, Int64?).self) { group in
                for item in batch {
                    group.addTask {
                        (item.id, await repository.size(of: item))
                    }
                }
                for await (id, size) in group {
                    if let size {
                        sizes[id] = size
                    }
                    measuringIDs.remove(id)
                }
            }
        }
    }
}
