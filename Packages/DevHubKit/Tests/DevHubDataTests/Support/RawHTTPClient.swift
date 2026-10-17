import Foundation
import Network

enum RawHTTPClient {

    static func send(_ request: Data, port: Int) async throws -> Data {
        guard let endpointPort = NWEndpoint.Port(rawValue: UInt16(port)) else { throw URLError(.badURL) }
        let connection = NWConnection(host: .ipv4(.loopback), port: endpointPort, using: .tcp)
        let exchange = RawHTTPExchange(connection: connection)
        return try await withCheckedThrowingContinuation { continuation in
            exchange.start(request, continuation: continuation)
        }
    }
}
