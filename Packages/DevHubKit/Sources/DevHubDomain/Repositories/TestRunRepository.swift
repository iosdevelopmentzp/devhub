import Foundation

package protocol TestRunRepository: Sendable {
    func run(_ request: TestRunRequest, onEvent: @escaping @Sendable (TestEvent) -> Void) async throws -> TestRunReport
}
