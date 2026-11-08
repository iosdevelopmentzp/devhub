import Foundation

package struct MockLaunchPreparation: Sendable {
    package struct Outcome: Hashable, Sendable {
        package let environment: [String: String]
        package let note: String?
        package let baseURL: String?

        package init(environment: [String: String], note: String?, baseURL: String?) {
            self.environment = environment
            self.note = note
            self.baseURL = baseURL
        }

        package static let none = Outcome(environment: [:], note: nil, baseURL: nil)
    }

    package let mockServer: any MockServerRepository

    package init(mockServer: any MockServerRepository) {
        self.mockServer = mockServer
    }

    package func prepare(udid: String, plan: LaunchPlan) async -> Outcome {
        guard let port = await mockServer.port(udid: udid) else { return .none }
        let baseURL = MockLaunchEnvironment.baseURL(port: port)
        let variables = MockLaunchEnvironment.variables(port: port, variable: plan.baseURLVariable)
        guard variables.isEmpty == false else {
            return Outcome(environment: [:], note: "Mock server on \(baseURL), but network.baseURLVariable is not set: the app is not redirected.", baseURL: nil)
        }
        do {
            let upstream = try MockUpstreamPolicy.upstream(for: plan.profile)
            if await mockServer.upstream(udid: udid) != upstream {
                await mockServer.retarget(udid: udid, upstream: upstream)
            }
            return Outcome(environment: variables, note: "Mock server on: \(baseURL) → \(upstream.host)", baseURL: baseURL)
        } catch {
            await mockServer.stop(udid: udid)
            return Outcome(environment: [:], note: "Mock server stopped: \(error.localizedDescription)", baseURL: nil)
        }
    }
}
