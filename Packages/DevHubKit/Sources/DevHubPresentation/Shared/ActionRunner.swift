import Foundation
import Observation
import DevHubDomain
import DevHubUI

@MainActor
@Observable
final class ActionRunner {
    private(set) var busyTitle: String?

    @ObservationIgnored private let activity: ActivityLog

    init(activity: ActivityLog) {
        self.activity = activity
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
        Task { [weak self] in
            guard let self else { return }
            do {
                try await work()
                activity.log(title, detail: detail, outcome: .success)
                busyTitle = nil
                onSuccess?()
            } catch {
                activity.log(failureTitle ?? "\(title) failed", detail: error.localizedDescription, outcome: .failure)
                busyTitle = nil
                onFailure?()
            }
            await completion?()
        }
    }
}
