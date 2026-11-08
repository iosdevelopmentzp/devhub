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
    private var tunnels: [ObjectIdentifier: WebSocketTunnel] = [:]
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

    var upstream: MockUpstream {
        lock.withLock { handler.upstream }
    }

    func retarget(upstream: MockUpstream) {
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

    func stop() async {
        let (open, tunnels) = lock.withLock {
            let open = Array(connections.values)
            let tunnels = Array(self.tunnels.values)
            connections = [:]
            self.tunnels = [:]
            boundPort = nil
            return (open, tunnels)
        }
        tunnels.forEach { $0.cancel() }
        open.forEach { $0.cancel() }
        guard listener.state != .cancelled else { return }
        _ = try? await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, any Error>) in
            let once = ResumeOnce(continuation)
            listener.stateUpdateHandler = { state in
                switch state {
                case .cancelled, .failed:
                    once.resume(with: .success(()))
                default:
                    break
                }
            }
            listener.cancel()
        }
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
        guard request.isWebSocketUpgrade == false else {
            openTunnel(for: request, on: connection, upstream: handler.upstream.url(forPath: request.path), id: id, startedAt: startedAt, onExchange: onExchange)
            return
        }
        Task { [weak self] in
            let result = await handler.handle(request, id: id, startedAt: startedAt)
            self?.send(result.response, on: connection)
            onExchange(result.exchange)
        }
    }

    private func openTunnel(
        for request: MockHTTPRequest,
        on connection: NWConnection,
        upstream: URL,
        id: Int,
        startedAt: Date,
        onExchange: @escaping @Sendable (NetworkRequest) -> Void
    ) {
        let tunnel = WebSocketTunnel(
            client: connection,
            request: request,
            upstream: upstream,
            id: id,
            startedAt: startedAt,
            queue: queue,
            onExchange: onExchange,
            onClose: { [weak self] key in
                guard let self else { return }
                _ = lock.withLock { tunnels.removeValue(forKey: key) }
            }
        )
        lock.withLock { tunnels[ObjectIdentifier(tunnel)] = tunnel }
        tunnel.open()
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
