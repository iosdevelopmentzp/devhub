import Foundation
import Observation
import DevHubDomain
import DevHubUI

@MainActor
@Observable
final class ActionRunner {
    private(set) var busyTitle: String?

    @ObservationIgnored private let activity: ActivityLog
    @ObservationIgnored private let operations: OperationLog
    @ObservationIgnored private let origin: OperationOrigin

    init(activity: ActivityLog, operations: OperationLog, origin: OperationOrigin) {
        self.activity = activity
        self.operations = operations
        self.origin = origin
    }

    func run(
        _ title: String,
        detail: String,
        failureTitle: String? = nil,
        onSuccess: (() -> Void)? = nil,
        onFailure: (() -> Void)? = nil,
        completion: (() async -> Void)? = nil,
        work: @escaping () async throws -> Void
    ) {
        busyTitle = title
        let retry: () -> Void = { [weak self] in
            guard let self, busyTitle == nil else { return }
            run(title, detail: detail, failureTitle: failureTitle, onSuccess: onSuccess, onFailure: onFailure, completion: completion, work: work)
        }
        let operationID = operations.start(title, at: origin, retry: retry, stop: nil)
        Task { [weak self] in
            guard let self else { return }
            do {
                try await OperationScope.$current.withValue(operationID) {
                    try await work()
                }
                operations.succeed(operationID)
                activity.log(title, detail: detail, outcome: .success)
                busyTitle = nil
                onSuccess?()
            } catch {
                operations.fail(operationID, message: error.localizedDescription)
                activity.log(failureTitle ?? "\(title) failed", detail: error.localizedDescription, outcome: .failure)
                busyTitle = nil
                onFailure?()
            }
            await completion?()
        }
    }
}
