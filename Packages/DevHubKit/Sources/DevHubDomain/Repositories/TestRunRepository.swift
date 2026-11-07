import Foundation

package protocol TestRunRepository: Sendable {
    func run(_ request: TestRunRequest, onEvent: @escaping @Sendable (TestEvent) -> Void) async throws -> TestRunReport
    func results(bundlePath: String, projectPath: String) async throws -> [TestResultCase]
    func exportAttachments(bundlePath: String) async throws -> [TestAttachment]
}
