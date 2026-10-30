import Foundation

package struct RunTestsUseCase: Sendable {
    package let tests: any TestRunRepository
    package let simulators: any SimulatorRepository

    package init(tests: any TestRunRepository, simulators: any SimulatorRepository) {
        self.tests = tests
        self.simulators = simulators
    }

    package func run(_ request: TestRunRequest) -> AsyncThrowingStream<TestEvent, Error> {
        AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    try await pipeline(request, continuation: continuation)
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    private func pipeline(_ request: TestRunRequest, continuation: AsyncThrowingStream<TestEvent, Error>.Continuation) async throws {
        continuation.yield(.step("Booting \(request.simulatorName)"))
        try await simulators.boot(udid: request.simulatorUDID)
        try Task.checkCancellation()

        continuation.yield(.step("Building \(request.scheme) for testing"))
        let report = try await tests.run(request) { continuation.yield($0) }
        try Task.checkCancellation()
        continuation.yield(.finished(report))
    }
}
