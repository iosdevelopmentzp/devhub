import Foundation

package struct RelaunchWithMocksUseCase: Sendable {
    package let mockServer: any MockServerRepository
    package let simulators: any SimulatorRepository
    package let identity: any DeviceIdentityRepository

    package func execute(_ request: MockRelaunchRequest, onExchange: @escaping @Sendable (NetworkRequest) -> Void) async throws -> MockServerState? {
        guard request.mode != .off else {
            await mockServer.stop(udid: request.udid)
            try await launch(request, environment: [:])
            return nil
        }
        guard let config = request.identity else { throw MockServerError.noIdentityConfig }
        let upstream = try UpstreamResolver.upstream(environment: request.environment, config: config)
        let rules: [MockRule]
        if request.mode == .mock {
            guard let set = request.set else { throw MockServerError.noSetChosen }
            rules = set.rules
        } else {
            rules = []
        }
        let port = try await mockServer.start(udid: request.udid, upstream: upstream, rules: rules, onExchange: onExchange)
        try await launch(request, environment: MockLaunchEnvironment.variables(port: port))
        return MockServerState(
            mode: request.mode,
            setID: request.mode == .mock ? request.set?.id : nil,
            upstreamHost: upstream.host ?? upstream.absoluteString,
            status: .running(port: port)
        )
    }

    private func launch(_ request: MockRelaunchRequest, environment: [String: String]) async throws {
        if let config = request.identity {
            _ = try await identity.launch(udid: request.udid, config: config, deviceID: request.deviceID, waitForDebugger: false, environment: environment)
            return
        }
        try await simulators.openInSimulatorApp(udid: request.udid)
        _ = try await simulators.launch(udid: request.udid, bundleID: request.bundleID, waitForDebugger: false, environment: environment)
    }
}
