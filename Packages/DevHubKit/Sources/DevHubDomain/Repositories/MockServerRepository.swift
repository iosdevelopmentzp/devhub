import Foundation

package protocol MockServerRepository: Sendable {
    func start(udid: String, upstream: MockUpstream, rules: [MockRule], onExchange: @escaping @Sendable (NetworkRequest) -> Void) async throws -> Int
    func update(udid: String, rules: [MockRule]) async
    func stop(udid: String) async
    func port(udid: String) async -> Int?
    func upstream(udid: String) async -> MockUpstream?
    func retarget(udid: String, upstream: MockUpstream) async
}
