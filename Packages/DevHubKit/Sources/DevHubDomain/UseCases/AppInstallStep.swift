import Foundation

package struct AppInstallStep: Sendable {
    package let simulators: any SimulatorRepository
    package let devices: any DeviceRepository
    package let attacher: any XcodeAttaching
    package let mockServer: any MockServerRepository

    package init(simulators: any SimulatorRepository, devices: any DeviceRepository, attacher: any XcodeAttaching, mockServer: any MockServerRepository) {
        self.simulators = simulators
        self.devices = devices
        self.attacher = attacher
        self.mockServer = mockServer
    }

    package func run(_ product: BuildProduct, request: BuildRequest, continuation: AsyncThrowingStream<BuildEvent, Error>.Continuation) async throws {
        guard request.isPhysicalDevice == false else {
            try await runOnDevice(product, request: request, continuation: continuation)
            return
        }
        try await simulators.waitUntilBooted(udid: request.simulatorUDID)
        if request.cleanInstall {
            continuation.yield(.step("Clean install: deleting the app and resetting the simulator keychain", progress: nil))
            await simulators.uninstallQuietly(udid: request.simulatorUDID, bundleID: product.bundleID)
            try await simulators.resetKeychain(udid: request.simulatorUDID)
        }

        continuation.yield(.step("Installing on \(request.simulatorName)", progress: nil))
        try await simulators.install(udid: request.simulatorUDID, appPath: product.appPath)

        if request.launch.defaults.isEmpty == false {
            continuation.yield(.step(Self.defaultsStep(request.launch), progress: nil))
            try await simulators.writeDefaults(udid: request.simulatorUDID, bundleID: product.bundleID, defaults: request.launch.defaults)
        }

        let pid = try await launch(product, request: request, continuation: continuation)

        guard request.attachDebugger else { return }
        guard let pid else { throw BuildError.failed("simctl launch did not report a process ID.") }
        continuation.yield(.output("Waiting for debugger, pid \(pid)"))
        continuation.yield(.step("Attaching Xcode to pid \(pid)", progress: nil))
        try await attacher.attach(pid: pid, destination: .simulator(request.simulatorUDID), projectPath: request.projectPath, container: request.container)
    }

    private func runOnDevice(_ product: BuildProduct, request: BuildRequest, continuation: AsyncThrowingStream<BuildEvent, Error>.Continuation) async throws {
        if request.cleanInstall {
            continuation.yield(.step("Clean install: removing the app from \(request.simulatorName)", progress: nil))
            try await devices.uninstall(udid: request.simulatorUDID, bundleID: product.bundleID)
        }

        continuation.yield(.step("Installing on \(request.simulatorName)", progress: nil))
        try await devices.install(udid: request.simulatorUDID, appPath: product.appPath)

        let plan = request.launch
        if plan.defaults.isEmpty == false {
            continuation.yield(.step(Self.defaultsStep(plan), progress: nil))
            try await devices.writeDefaults(udid: request.simulatorUDID, bundleID: product.bundleID, defaults: plan.defaults)
        }

        continuation.yield(.step(Self.launchStep(product, plan: plan), progress: nil))
        let pid = try await devices.launch(udid: request.simulatorUDID, bundleID: product.bundleID, environment: plan.environment, arguments: plan.arguments, startStopped: request.attachDebugger)
        continuation.yield(.launched(plan.record(bundleID: product.bundleID, baseURL: nil, date: .now)))
        guard request.attachDebugger else { return }
        guard let pid else { throw BuildError.failed("devicectl did not report a process ID.") }
        continuation.yield(.output("Started stopped, pid \(pid)"))
        continuation.yield(.step("Attaching Xcode to pid \(pid)", progress: nil))
        try await attacher.attach(pid: pid, destination: .device(request.simulatorUDID), projectPath: request.projectPath, container: request.container)
    }

    private func launch(
        _ product: BuildProduct,
        request: BuildRequest,
        continuation: AsyncThrowingStream<BuildEvent, Error>.Continuation
    ) async throws -> Int32? {
        let plan = request.launch
        let mocks = await MockLaunchPreparation(mockServer: mockServer).prepare(udid: request.simulatorUDID, plan: plan)
        if let note = mocks.note {
            continuation.yield(.output(note))
        }
        continuation.yield(.step(Self.launchStep(product, plan: plan), progress: nil))
        try await simulators.openInSimulatorApp(udid: request.simulatorUDID)
        let pid = try await simulators.launch(
            udid: request.simulatorUDID,
            bundleID: product.bundleID,
            waitForDebugger: request.attachDebugger,
            environment: plan.environment.merging(mocks.environment) { _, mock in mock },
            arguments: plan.arguments
        )
        continuation.yield(.launched(plan.record(bundleID: product.bundleID, baseURL: mocks.baseURL, date: .now)))
        return pid
    }

    private static func defaultsStep(_ plan: LaunchPlan) -> String {
        "Writing \(plan.defaults.count == 1 ? "1 default" : "\(plan.defaults.count) defaults") of the launch profile"
    }

    private static func launchStep(_ product: BuildProduct, plan: LaunchPlan) -> String {
        "Launching \(product.bundleID)" + (plan.identity.map { " · ID \($0)" } ?? "")
    }
}
