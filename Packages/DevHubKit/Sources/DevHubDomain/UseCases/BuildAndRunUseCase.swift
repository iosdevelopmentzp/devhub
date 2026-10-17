import Foundation

package struct BuildAndRunUseCase: Sendable {
    package let build: any BuildRepository
    package let simulators: any SimulatorRepository
    package let identity: any DeviceIdentityRepository
    package let attacher: any XcodeAttaching
    package let mockServer: any MockServerRepository

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

        if request.cleanInstall {
            continuation.yield(.step("Clean install: deleting the app and resetting the simulator keychain", progress: nil))
            await simulators.uninstallQuietly(udid: request.simulatorUDID, bundleID: product.bundleID)
            try await simulators.resetKeychain(udid: request.simulatorUDID)
        }

        continuation.yield(.step("Installing on \(request.simulatorName)", progress: nil))
        try await simulators.install(udid: request.simulatorUDID, appPath: product.appPath)

        let pid = try await launch(product, request: request, continuation: continuation)

        guard request.attachDebugger else { return }
        guard let pid else { throw BuildError.failed("simctl launch did not report a process ID.") }
        continuation.yield(.output("Waiting for debugger, pid \(pid)"))
        continuation.yield(.step("Attaching Xcode to pid \(pid)", progress: nil))
        try await attacher.attach(pid: pid, simulatorUDID: request.simulatorUDID, projectPath: request.projectPath)
    }

    private func launch(
        _ product: BuildProduct,
        request: BuildRequest,
        continuation: AsyncThrowingStream<BuildEvent, Error>.Continuation
    ) async throws -> Int32? {
        let mocks = await MockLaunchPreparation(identity: identity, mockServer: mockServer).prepare(
            udid: request.simulatorUDID,
            config: request.identity?.config,
            environment: request.identity?.environment
        )
        let environment = mocks.environment
        if let note = mocks.note {
            continuation.yield(.output(note))
        }
        guard let buildIdentity = request.identity else {
            continuation.yield(.step("Launching \(product.bundleID)", progress: nil))
            try await simulators.openInSimulatorApp(udid: request.simulatorUDID)
            return try await simulators.launch(udid: request.simulatorUDID, bundleID: product.bundleID, waitForDebugger: request.attachDebugger, environment: environment)
        }
        if let environment = buildIdentity.environment {
            continuation.yield(.step("Setting environment \(environment)", progress: nil))
            try await identity.setEnvironment(environment, udid: request.simulatorUDID, config: buildIdentity.config)
        }
        continuation.yield(.step("Launching \(product.bundleID)" + (buildIdentity.deviceID.map { " · device ID \($0)" } ?? ""), progress: nil))
        return try await identity.launch(
            udid: request.simulatorUDID,
            config: buildIdentity.config,
            deviceID: buildIdentity.deviceID,
            waitForDebugger: request.attachDebugger,
            environment: environment
        )
    }
}
