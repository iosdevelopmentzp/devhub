import Foundation

package struct AppInstallStep: Sendable {
    package let simulators: any SimulatorRepository
    package let attacher: any XcodeAttaching
    package let mockServer: any MockServerRepository

    package init(simulators: any SimulatorRepository, attacher: any XcodeAttaching, mockServer: any MockServerRepository) {
        self.simulators = simulators
        self.attacher = attacher
        self.mockServer = mockServer
    }

    package func run(_ product: BuildProduct, request: BuildRequest, continuation: AsyncThrowingStream<BuildEvent, Error>.Continuation) async throws {
        try await simulators.waitUntilBooted(udid: request.simulatorUDID)
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
        let plan = request.launch
        let mocks = await MockLaunchPreparation(mockServer: mockServer).prepare(udid: request.simulatorUDID, plan: plan)
        if let note = mocks.note {
            continuation.yield(.output(note))
        }
        continuation.yield(.step("Launching \(product.bundleID)" + (plan.identity.map { " · ID \($0)" } ?? ""), progress: nil))
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
}
