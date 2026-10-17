import Foundation
import Network
import DevHubDomain

final class LocalMockServer: @unchecked Sendable {
    private static let firstExchangeID = 1 << 32
    private static let readChunk = 1 << 16

    private let lock = NSLock()
    private let queue = DispatchQueue(label: "DevHub.LocalMockServer")
    private let listener: NWListener
    private var handler: MockExchangeHandler
    private var onExchange: @Sendable (NetworkRequest) -> Void
    private var nextID = LocalMockServer.firstExchangeID
    private var connections: [ObjectIdentifier: NWConnection] = [:]
    private var boundPort: Int?

    init(handler: MockExchangeHandler, onExchange: @escaping @Sendable (NetworkRequest) -> Void, preferredPort: Int?) throws {
        let parameters = NWParameters.tcp
        parameters.acceptLocalOnly = true
        parameters.allowLocalEndpointReuse = true
        let port = preferredPort.flatMap { NWEndpoint.Port(rawValue: UInt16($0)) } ?? .any
        parameters.requiredLocalEndpoint = NWEndpoint.hostPort(host: .ipv4(.loopback), port: port)
        listener = try NWListener(using: parameters)
        self.handler = handler
        self.onExchange = onExchange
    }

    var port: Int? {
        lock.withLock { boundPort }
    }

    var upstream: URL {
        lock.withLock { handler.upstream }
    }

    func retarget(upstream: URL) {
        lock.withLock {
            handler = MockExchangeHandler(upstream: upstream, rules: handler.rules, forwarder: handler.forwarder)
        }
    }

    func start() async throws -> Int {
        let port: Int = try await withCheckedThrowingContinuation { continuation in
            let once = ResumeOnce(continuation)
            listener.stateUpdateHandler = { [weak listener] state in
                switch state {
                case .ready:
                    once.resume(with: .success(Int(listener?.port?.rawValue ?? 0)))
                case .failed(let error):
                    once.resume(with: .failure(MockServerError.startFailed(error.localizedDescription)))
                    listener?.cancel()
                case .cancelled:
                    once.resume(with: .failure(MockServerError.startFailed("The listener was cancelled.")))
                default:
                    break
                }
            }
            listener.newConnectionHandler = { [weak self] connection in
                guard let self else {
                    connection.cancel()
                    return
                }
                accept(connection)
            }
            listener.start(queue: queue)
        }
        lock.withLock { boundPort = port }
        return port
    }

    func configure(handler: MockExchangeHandler, onExchange: @escaping @Sendable (NetworkRequest) -> Void) {
        lock.withLock {
            self.handler = handler
            self.onExchange = onExchange
        }
    }

    func update(rules: [MockRule]) {
        lock.withLock {
            handler = MockExchangeHandler(upstream: handler.upstream, rules: rules, forwarder: handler.forwarder)
        }
    }

    func stop() {
        let open = lock.withLock {
            let open = Array(connections.values)
            connections = [:]
            boundPort = nil
            return open
        }
        listener.cancel()
        open.forEach { $0.cancel() }
    }

    private func accept(_ connection: NWConnection) {
        let key = ObjectIdentifier(connection)
        lock.withLock { connections[key] = connection }
        connection.stateUpdateHandler = { [weak self] state in
            switch state {
            case .failed, .cancelled:
                guard let self else { return }
                _ = lock.withLock { connections.removeValue(forKey: key) }
            default:
                break
            }
        }
        connection.start(queue: queue)
        receive(on: connection, buffer: Data())
    }

    private func receive(on connection: NWConnection, buffer: Data) {
        connection.receive(minimumIncompleteLength: 1, maximumLength: Self.readChunk) { [weak self] data, _, isComplete, error in
            guard let self else {
                connection.cancel()
                return
            }
            var buffer = buffer
            if let data {
                buffer.append(data)
            }
            switch HTTPRequestParser.parse(buffer) {
            case .complete(let request):
                respond(to: request, on: connection)
            case .incomplete:
                if isComplete || error != nil {
                    connection.cancel()
                } else {
                    receive(on: connection, buffer: buffer)
                }
            case .unsupported(let reason):
                send(.text(501, reason), on: connection)
            case .invalid(let reason):
                send(.text(400, reason), on: connection)
            }
        }
    }

    private func respond(to request: MockHTTPRequest, on connection: NWConnection) {
        let (handler, onExchange, id) = lock.withLock {
            defer { nextID += 1 }
            return (self.handler, self.onExchange, nextID)
        }
        let startedAt = Date()
        Task { [weak self] in
            let result = await handler.handle(request, id: id, startedAt: startedAt)
            self?.send(result.response, on: connection)
            onExchange(result.exchange)
        }
    }

    private func send(_ response: MockHTTPResponse, on connection: NWConnection) {
        connection.send(content: HTTPResponseSerializer.data(for: response), contentContext: .finalMessage, isComplete: true, completion: .contentProcessed { _ in
            connection.cancel()
        })
    }
}

private final class ResumeOnce<Value: Sendable>: @unchecked Sendable {
    private let lock = NSLock()
    private var continuation: CheckedContinuation<Value, any Error>?

    init(_ continuation: CheckedContinuation<Value, any Error>) {
        self.continuation = continuation
    }

    func resume(with result: Result<Value, any Error>) {
        let pending = lock.withLock {
            defer { continuation = nil }
            return continuation
        }
        pending?.resume(with: result)
    }
}
