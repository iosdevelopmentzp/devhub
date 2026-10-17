import Foundation

package struct MockLaunchPreparation: Sendable {
    package struct Outcome: Hashable, Sendable {
        package let environment: [String: String]
        package let note: String?

        package init(environment: [String: String], note: String?) {
            self.environment = environment
            self.note = note
        }

        package static let none = Outcome(environment: [:], note: nil)
    }

    package let identity: any DeviceIdentityRepository
    package let mockServer: any MockServerRepository

    package init(identity: any DeviceIdentityRepository, mockServer: any MockServerRepository) {
        self.identity = identity
        self.mockServer = mockServer
    }

    package func prepare(udid: String, config: DeviceIdentityConfig?, environment: String?) async -> Outcome {
        guard let port = await mockServer.port(udid: udid) else { return .none }
        let variables = MockLaunchEnvironment.variables(port: port)
        let baseURL = MockLaunchEnvironment.baseURL(port: port)
        guard let config else { return Outcome(environment: variables, note: "Mock server on: \(baseURL)") }
        var name = environment
        if name == nil {
            name = await identity.read(udid: udid, config: config).storedEnvironment
        }
        do {
            let upstream = try UpstreamResolver.upstream(environment: name, config: config)
            if await mockServer.upstream(udid: udid) != upstream {
                await mockServer.retarget(udid: udid, upstream: upstream)
            }
            return Outcome(environment: variables, note: "Mock server on: \(baseURL) → \(upstream.host ?? upstream.absoluteString)")
        } catch {
            await mockServer.stop(udid: udid)
            return Outcome(environment: [:], note: "Mock server stopped: \(error.localizedDescription)")
        }
    }
}
