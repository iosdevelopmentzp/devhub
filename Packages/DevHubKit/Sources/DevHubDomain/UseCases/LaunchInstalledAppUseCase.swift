import Foundation

package struct LaunchInstalledAppUseCase: Sendable {
    package let launcher: any AppLaunchRepository
    package let simulators: any SimulatorRepository
    package let devices: any DeviceRepository
    package let attacher: any XcodeAttaching
    package let mockServer: any MockServerRepository

    package func execute(_ request: IdentityLaunch, cleanInstall: Bool) async throws -> LaunchRecord {
        guard request.simulator.isPhysical == false else {
            return try await executeOnDevice(request, cleanInstall: cleanInstall)
        }
        let udid = request.simulator.id
        let plan = request.plan
        try await simulators.boot(udid: udid)
        try await simulators.waitUntilBooted(udid: udid)
        if cleanInstall {
            try await launcher.cleanInstall(udid: udid, bundleID: request.bundleID, fallbackAppPath: request.fallbackAppPath)
        }
        if plan.defaults.isEmpty == false {
            try await simulators.writeDefaults(udid: udid, bundleID: request.bundleID, defaults: plan.defaults)
        }
        let mocks = await MockLaunchPreparation(mockServer: mockServer).prepare(udid: udid, plan: plan)
        try await simulators.openInSimulatorApp(udid: udid)
        let pid = try await simulators.launch(
            udid: udid,
            bundleID: request.bundleID,
            waitForDebugger: request.attachDebugger,
            environment: plan.environment.merging(mocks.environment) { _, mock in mock },
            arguments: plan.arguments
        )
        let record = plan.record(bundleID: request.bundleID, baseURL: mocks.baseURL, date: .now)
        guard request.attachDebugger else { return record }
        guard let pid else { throw XcodeAttachError.script("simctl launch did not report a process ID.") }
        try await attacher.attach(pid: pid, destination: .simulator(udid), projectPath: request.projectPath, container: request.container)
        return record
    }

    private func executeOnDevice(_ request: IdentityLaunch, cleanInstall: Bool) async throws -> LaunchRecord {
        let udid = request.simulator.id
        let plan = request.plan
        if cleanInstall {
            guard let appPath = request.fallbackAppPath else { throw AppLaunchError.noAppToReinstall }
            try await devices.uninstall(udid: udid, bundleID: request.bundleID)
            try await devices.install(udid: udid, appPath: appPath)
        }
        if plan.defaults.isEmpty == false {
            try await devices.writeDefaults(udid: udid, bundleID: request.bundleID, defaults: plan.defaults)
        }
        let pid = try await devices.launch(udid: udid, bundleID: request.bundleID, environment: plan.environment, arguments: plan.arguments, startStopped: request.attachDebugger)
        let record = plan.record(bundleID: request.bundleID, baseURL: nil, date: .now)
        guard request.attachDebugger else { return record }
        guard let pid else { throw XcodeAttachError.script("devicectl did not report a process ID.") }
        try await attacher.attach(pid: pid, destination: .device(udid), projectPath: request.projectPath, container: request.container)
        return record
    }
}
