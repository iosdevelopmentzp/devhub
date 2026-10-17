import Foundation

@MainActor
package func waitUntil(timeout: Duration = .seconds(10), _ condition: @MainActor @escaping () -> Bool) async throws {
    let deadline = ContinuousClock.now.advanced(by: timeout)
    while condition() == false {
        guard ContinuousClock.now < deadline else { throw TestError.timedOut }
        await Task.yield()
        try await Task.sleep(for: .milliseconds(5))
    }
}
