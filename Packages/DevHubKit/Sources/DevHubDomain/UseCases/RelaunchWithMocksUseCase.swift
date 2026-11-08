import Foundation

package struct RelaunchWithMocksUseCase: Sendable {
    package struct Result: Sendable {
        package let state: MockServerState?
        package let launch: LaunchRecord
    }

    package let mockServer: any MockServerRepository
    package let simulators: any SimulatorRepository

    package func execute(_ request: MockRelaunchRequest, onExchange: @escaping @Sendable (NetworkRequest) -> Void) async throws -> Result {
        guard request.mode != .off else {
            await mockServer.stop(udid: request.udid)
            try await launch(request, environment: [:])
            return Result(state: nil, launch: request.plan.record(bundleID: request.bundleID, baseURL: nil, date: .now))
        }
        guard let variable = request.plan.baseURLVariable, variable.trimmed.isEmpty == false else { throw MockServerError.disabled }
        let upstream = try MockUpstreamPolicy.upstream(for: request.plan.profile)
        let rules: [MockRule]
        if request.mode == .mock {
            guard let set = request.set else { throw MockServerError.noSetChosen }
            rules = set.rules
        } else {
            rules = []
        }
        let port = try await mockServer.start(udid: request.udid, upstream: upstream, rules: rules, onExchange: onExchange)
        try await launch(request, environment: MockLaunchEnvironment.variables(port: port, variable: variable))
        let state = MockServerState(
            mode: request.mode,
            setID: request.mode == .mock ? request.set?.id : nil,
            upstreamHost: upstream.host,
            status: .running(port: port)
        )
        return Result(state: state, launch: request.plan.record(bundleID: request.bundleID, baseURL: MockLaunchEnvironment.baseURL(port: port), date: .now))
    }

    private func launch(_ request: MockRelaunchRequest, environment: [String: String]) async throws {
        if request.plan.defaults.isEmpty == false {
            try await simulators.writeDefaults(udid: request.udid, bundleID: request.bundleID, defaults: request.plan.defaults)
        }
        try await simulators.openInSimulatorApp(udid: request.udid)
        _ = try await simulators.launch(
            udid: request.udid,
            bundleID: request.bundleID,
            waitForDebugger: false,
            environment: request.plan.environment.merging(environment) { _, mock in mock },
            arguments: request.plan.arguments
        )
    }
}
