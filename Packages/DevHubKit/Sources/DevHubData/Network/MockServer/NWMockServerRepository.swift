import Foundation
import DevHubDomain

actor NWMockServerRepository: MockServerRepository {
    private let forwarder: HTTPForwarder
    private var servers: [String: LocalMockServer] = [:]

    init(session: URLSession) {
        forwarder = HTTPForwarder(session: session)
    }

    func start(udid: String, upstream: URL, rules: [MockRule], onExchange: @escaping @Sendable (NetworkRequest) -> Void) async throws -> Int {
        let handler = MockExchangeHandler(upstream: upstream, rules: rules, forwarder: forwarder)
        if let server = servers[udid], let port = server.port {
            server.configure(handler: handler, onExchange: onExchange)
            return port
        }
        let server = try await startServer(handler: handler, onExchange: onExchange, preferredPort: MockServerPortPolicy.port(for: udid))
        await servers.removeValue(forKey: udid)?.stop()
        servers[udid] = server
        return server.port ?? 0
    }

    private func startServer(
        handler: MockExchangeHandler,
        onExchange: @escaping @Sendable (NetworkRequest) -> Void,
        preferredPort: Int?
    ) async throws -> LocalMockServer {
        let server: LocalMockServer
        do {
            server = try LocalMockServer(handler: handler, onExchange: onExchange, preferredPort: preferredPort)
        } catch {
            throw MockServerError.startFailed(error.localizedDescription)
        }
        do {
            _ = try await server.start()
            return server
        } catch {
            guard preferredPort != nil else { throw error }
            return try await startServer(handler: handler, onExchange: onExchange, preferredPort: nil)
        }
    }

    func update(udid: String, rules: [MockRule]) async {
        servers[udid]?.update(rules: rules)
    }

    func stop(udid: String) async {
        await servers.removeValue(forKey: udid)?.stop()
    }

    func port(udid: String) async -> Int? {
        servers[udid]?.port
    }

    func upstream(udid: String) async -> URL? {
        servers[udid]?.upstream
    }

    func retarget(udid: String, upstream: URL) async {
        servers[udid]?.retarget(upstream: upstream)
    }
}
