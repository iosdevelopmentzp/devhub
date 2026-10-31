import Foundation
import Observation
import DevHubDomain
import DevHubUI

@MainActor
@Observable
final class OperationLog {
    static let finishedLimit = 30

    private(set) var records: [OperationRecord] = []

    @ObservationIgnored private var retries: [OperationRecord.ID: () -> Void] = [:]
    @ObservationIgnored private var stops: [OperationRecord.ID: () -> Void] = [:]

    var running: [OperationRecord] {
        records.filter(\.isRunning)
    }

    var newestFirst: [OperationRecord] {
        records.reversed()
    }

    var unseenFailureCount: Int {
        records.filter { $0.failureMessage != nil && $0.isSeen == false }.count
    }

    func latest(at origin: OperationOrigin) -> OperationRecord? {
        records.last { $0.origin == origin && $0.isDismissed == false }
    }

    func record(_ id: OperationRecord.ID) -> OperationRecord? {
        records.first { $0.id == id }
    }

    @discardableResult
    func start(_ title: String, at origin: OperationOrigin, retry: (() -> Void)?, stop: (() -> Void)?) -> OperationRecord.ID {
        for index in records.indices where records[index].origin == origin && records[index].isRunning == false {
            records[index].isDismissed = true
        }
        let id = UUID()
        records.append(OperationRecord(
            id: id,
            title: title,
            origin: origin,
            startedAt: Date(),
            status: .running,
            canRetry: retry != nil,
            canStop: stop != nil,
            isDismissed: false,
            isSeen: false,
            isOutputOpen: false
        ))
        retries[id] = retry
        stops[id] = stop
        return id
    }

    func setProgress(of id: OperationRecord.ID, text: String, fraction: Double?) {
        update(id) {
            $0.progressText = text
            $0.fraction = fraction
        }
    }

    func succeed(_ id: OperationRecord.ID) {
        finish(id, status: .succeeded)
    }

    func fail(_ id: OperationRecord.ID, message: String) {
        finish(id, status: .failed(message))
    }

    func cancel(_ id: OperationRecord.ID) {
        finish(id, status: .cancelled)
    }

    func dismiss(_ id: OperationRecord.ID) {
        update(id) {
            $0.isDismissed = true
            $0.isSeen = true
        }
    }

    func retry(_ id: OperationRecord.ID) {
        guard let retry = retries[id], record(id)?.isRunning == false else { return }
        dismiss(id)
        retry()
    }

    func stop(_ id: OperationRecord.ID) {
        stops[id]?()
    }

    func toggleOutput(of id: OperationRecord.ID) {
        update(id) { $0.isOutputOpen.toggle() }
    }

    func remove(_ id: OperationRecord.ID) {
        guard record(id)?.isRunning == false else { return }
        records.removeAll { $0.id == id }
        retries[id] = nil
    }

    func clearFinished() {
        let removed = Set(records.filter { $0.isRunning == false }.map(\.id))
        records.removeAll { removed.contains($0.id) }
        for id in removed {
            retries[id] = nil
        }
    }

    func markAllSeen() {
        for index in records.indices where records[index].isRunning == false {
            records[index].isSeen = true
        }
    }

    private func finish(_ id: OperationRecord.ID, status: OperationRecord.Status) {
        update(id) {
            $0.status = status
            $0.finishedAt = Date()
            $0.canStop = false
        }
        stops[id] = nil
        trim()
    }

    private func update(_ id: OperationRecord.ID, _ change: (inout OperationRecord) -> Void) {
        guard let index = records.firstIndex(where: { $0.id == id }) else { return }
        change(&records[index])
    }

    private func trim() {
        let finished = records.filter { $0.isRunning == false }
        let overflow = finished.count - Self.finishedLimit
        guard overflow > 0 else { return }
        let removed = Set(finished.prefix(overflow).map(\.id))
        records.removeAll { removed.contains($0.id) }
        for id in removed {
            retries[id] = nil
        }
    }
}
