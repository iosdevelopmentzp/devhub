import Foundation

package struct AppInstallStep: Sendable {
    package let simulators: any SimulatorRepository
    package let identity: any DeviceIdentityRepository
    package let attacher: any XcodeAttaching
    package let mockServer: any MockServerRepository

    package init(simulators: any SimulatorRepository, identity: any DeviceIdentityRepository, attacher: any XcodeAttaching, mockServer: any MockServerRepository) {
        self.simulators = simulators
        self.identity = identity
        self.attacher = attacher
        self.mockServer = mockServer
    }

    package func run(_ product: BuildProduct, request: BuildRequest, continuation: AsyncThrowingStream<BuildEvent, Error>.Continuation) async throws {
        if request.cleanInstall {
            continuation.yield(.step("Clean install: deleting the app and resetting the simulator keychain", progress: nil))
            await simulators.uninstallQuietly(udid: request.simulatorUDID, bundleID: product.bundleID)
            try await simulators.resetKeychain(udid: request.simulatorUDID)
        }

        continuation.yield(.step("Installing on \(request.simulatorName)", progress: nil))
        try await simulators.install(udid: request.simulatorUDID, appPath: product.appPath)

        if request.launch.defaults.isEmpty == false {
            continuation.yield(.step("Writing \(request.launch.defaults.count == 1 ? "1 default" : "\(request.launch.defaults.count) defaults") of the launch profile", progress: nil))
            try await simulators.writeDefaults(udid: request.simulatorUDID, bundleID: product.bundleID, defaults: request.launch.defaults)
        }

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
        let environment = request.launch.environment.merging(mocks.environment) { _, mock in mock }
        if let note = mocks.note {
            continuation.yield(.output(note))
        }
        guard let buildIdentity = request.identity else {
            continuation.yield(.step("Launching \(product.bundleID)", progress: nil))
            try await simulators.openInSimulatorApp(udid: request.simulatorUDID)
            return try await simulators.launch(udid: request.simulatorUDID, bundleID: product.bundleID, waitForDebugger: request.attachDebugger, environment: environment, arguments: request.launch.arguments)
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
            environment: environment,
            arguments: request.launch.arguments
        )
    }
}
