import Foundation
import DevHubDomain

struct MockTestRunRepository: TestRunRepository {

    func run(_ request: TestRunRequest, onEvent: @escaping @Sendable (TestEvent) -> Void) async throws -> TestRunReport {
        onEvent(.step("Compiling \(request.scheme)Tests"))
        try await Task.sleep(for: .milliseconds(600))
        onEvent(.step("Running tests"))
        for result in MockData.testResults {
            try await Task.sleep(for: .milliseconds(250))
            onEvent(.testFinished(result))
        }
        for failure in MockData.testFailures {
            onEvent(.failure(failure))
        }
        return TestRunReport(status: MockData.testFailures.isEmpty ? .passed : .failed, resultBundlePath: "/tmp/DevHub-tests/\(request.scheme).xcresult")
    }

    func results(bundlePath: String, projectPath: String) async throws -> [TestResultCase] {
        MockData.testCases
    }

    func exportAttachments(bundlePath: String) async throws -> [TestAttachment] {
        [TestAttachment(testIdentifier: "LoginTests/testLoginWithWrongPassword()", name: "Server answer", path: "/tmp/DevHub-tests/Attachments/answer.txt", isAssociatedWithFailure: true)]
    }
}
