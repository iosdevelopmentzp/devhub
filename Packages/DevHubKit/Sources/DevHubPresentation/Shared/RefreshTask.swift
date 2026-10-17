import Foundation
import DevHubDomain
import DevHubUI

@MainActor
final class RefreshTask {
    private var task: Task<Void, Never>?

    func run(_ work: @escaping @MainActor () async throws -> Void) async {
        task?.cancel()
        let current = Task { @MainActor in
            do {
                try await work()
            } catch {}
        }
        task = current
        await current.value
    }
}
