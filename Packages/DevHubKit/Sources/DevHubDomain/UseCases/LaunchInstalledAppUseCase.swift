import Foundation

package struct LaunchInstalledAppUseCase: Sendable {
    package let identity: any DeviceIdentityRepository
    package let attacher: any XcodeAttaching
    package let mockServer: any MockServerRepository

    package func execute(_ request: IdentityLaunch, config: DeviceIdentityConfig, cleanInstall: Bool) async throws {
        let udid = request.simulator.id
        if cleanInstall {
            try await identity.cleanInstall(udid: udid, config: config, fallbackAppPath: request.fallbackAppPath)
        }
        if let environment = request.environment {
            try await identity.setEnvironment(environment, udid: udid, config: config)
        }
        let environment = await MockLaunchPreparation(identity: identity, mockServer: mockServer).prepare(udid: udid, config: config, environment: request.environment).environment
        let pid = try await identity.launch(udid: udid, config: config, deviceID: request.deviceID, waitForDebugger: request.attachDebugger, environment: environment)
        guard request.attachDebugger else { return }
        guard let pid else { throw XcodeAttachError.script("simctl launch did not report a process ID.") }
        try await attacher.attach(pid: pid, simulatorUDID: udid, projectPath: request.projectPath)
    }
}
