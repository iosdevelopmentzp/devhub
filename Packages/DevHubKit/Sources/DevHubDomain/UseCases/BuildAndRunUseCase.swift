import Foundation

package struct BuildAndRunUseCase: Sendable {
    package let build: any BuildRepository
    package let simulators: any SimulatorRepository
    package let install: AppInstallStep

    package init(build: any BuildRepository, simulators: any SimulatorRepository, identity: any DeviceIdentityRepository, attacher: any XcodeAttaching, mockServer: any MockServerRepository) {
        self.build = build
        self.simulators = simulators
        install = AppInstallStep(simulators: simulators, identity: identity, attacher: attacher, mockServer: mockServer)
    }

    package func run(_ request: BuildRequest) -> AsyncThrowingStream<BuildEvent, Error> {
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

    private func pipeline(_ request: BuildRequest, continuation: AsyncThrowingStream<BuildEvent, Error>.Continuation) async throws {
        let onEvent: @Sendable (BuildEvent) -> Void = { continuation.yield($0) }

        continuation.yield(.step("Booting \(request.simulatorName)", progress: nil))
        try await simulators.boot(udid: request.simulatorUDID)
        try Task.checkCancellation()

        if request.incremental == false {
            continuation.yield(.step("Cleaning", progress: nil))
            try await build.clean(request, onEvent: onEvent)
        }

        continuation.yield(.step("Building \(request.scheme)", progress: nil))
        let appPathHints = try await build.build(request, onEvent: onEvent)

        continuation.yield(.step("Locating app", progress: nil))
        let product = try await build.locateProduct(request, hints: appPathHints)
        continuation.yield(.output("App: \(product.appPath)"))

        try await install.run(product, request: request, continuation: continuation)
    }
}
