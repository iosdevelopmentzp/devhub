import Foundation
import Network

final class WebSocketEchoServer: @unchecked Sendable {
    private let lock = NSLock()
    private let queue = DispatchQueue(label: "WebSocketEchoServer")
    private let listener: NWListener
    private var continuation: CheckedContinuation<Int, any Error>?

    init() throws {
        let parameters = NWParameters.tcp
        parameters.defaultProtocolStack.applicationProtocols.insert(NWProtocolWebSocket.Options(), at: 0)
        parameters.requiredLocalEndpoint = NWEndpoint.hostPort(host: .ipv4(.loopback), port: .any)
        listener = try NWListener(using: parameters)
    }

    func start() async throws -> Int {
        try await withCheckedThrowingContinuation { continuation in
            lock.withLock { self.continuation = continuation }
            listener.stateUpdateHandler = { [weak self] state in
                guard let self else { return }
                switch state {
                case .ready:
                    resume(with: .success(Int(listener.port?.rawValue ?? 0)))
                case .failed(let error):
                    resume(with: .failure(error))
                default:
                    break
                }
            }
            listener.newConnectionHandler = { [queue] connection in
                connection.start(queue: queue)
                Self.echo(on: connection)
            }
            listener.start(queue: queue)
        }
    }

    func stop() {
        listener.cancel()
    }

    private func resume(with result: Result<Int, any Error>) {
        let pending = lock.withLock {
            defer { continuation = nil }
            return continuation
        }
        pending?.resume(with: result)
    }

    private static func echo(on connection: NWConnection) {
        connection.receiveMessage { data, context, _, error in
            guard error == nil, let data else { return }
            let metadata = context?.protocolMetadata(definition: NWProtocolWebSocket.definition) as? NWProtocolWebSocket.Metadata
            let reply = NWConnection.ContentContext(identifier: "echo", metadata: [NWProtocolWebSocket.Metadata(opcode: metadata?.opcode ?? .text)])
            connection.send(content: data, contentContext: reply, isComplete: true, completion: .contentProcessed { _ in
                echo(on: connection)
            })
        }
    }
}
