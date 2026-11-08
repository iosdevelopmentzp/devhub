import Foundation
import Network
import DevHubDomain

final class WebSocketTunnel: @unchecked Sendable {
    private static let readChunk = 1 << 16
    private static let flushDelay: DispatchTimeInterval = .milliseconds(300)

    private let client: NWConnection
    private let request: MockHTTPRequest
    private let upstream: URL
    private let queue: DispatchQueue
    private let onExchange: @Sendable (NetworkRequest) -> Void
    private let onClose: @Sendable (ObjectIdentifier) -> Void
    private let clock = ContinuousClock()
    private let start: ContinuousClock.Instant
    private var server: NWConnection?
    private var exchange: NetworkRequest
    private var transcript = WebSocketTranscript()
    private var sent = WebSocketFrameReader()
    private var received = WebSocketFrameReader()
    private var head = Data()
    private var isOpen = false
    private var hasAnswered = false
    private var isClosed = false
    private var isFlushScheduled = false

    init(
        client: NWConnection,
        request: MockHTTPRequest,
        upstream: URL,
        id: Int,
        startedAt: Date,
        queue: DispatchQueue,
        onExchange: @escaping @Sendable (NetworkRequest) -> Void,
        onClose: @escaping @Sendable (ObjectIdentifier) -> Void
    ) {
        self.client = client
        self.request = request
        self.upstream = upstream
        self.queue = queue
        self.onExchange = onExchange
        self.onClose = onClose
        start = clock.now
        exchange = NetworkRequest(
            id: id,
            method: request.method,
            url: WebSocketHandshake.webSocketURL(upstream: upstream, target: request.target),
            path: request.path,
            host: upstream.host ?? "",
            statusCode: nil,
            statusText: "",
            startedAt: startedAt,
            duration: nil,
            requestBody: "",
            responseBody: "",
            responseHeaders: [],
            error: nil,
            isFailure: false,
            requestHeaders: request.headers
        )
    }

    func open() {
        guard let endpoint = WebSocketHandshake.endpoint(for: upstream),
              let port = NWEndpoint.Port(rawValue: UInt16(clamping: endpoint.port)),
              let headData = WebSocketHandshake.requestHead(for: request, upstream: upstream) else {
            fail("The upstream URL \(upstream.absoluteString) is not valid.")
            return
        }
        let parameters = endpoint.isSecure ? NWParameters(tls: NWProtocolTLS.Options(), tcp: NWProtocolTCP.Options()) : NWParameters.tcp
        let server = NWConnection(host: NWEndpoint.Host(endpoint.host), port: port, using: parameters)
        self.server = server
        server.stateUpdateHandler = { [weak self] state in
            guard let self else { return }
            switch state {
            case .ready:
                server.send(content: headData, completion: .contentProcessed { [weak self] error in
                    guard let self else { return }
                    if let error {
                        fail("Could not send the WebSocket handshake: \(error.localizedDescription)")
                    }
                })
                readHead(from: server)
            case .waiting(let error), .failed(let error):
                fail("Upstream \(endpoint.host) failed: \(error.localizedDescription)")
            default:
                break
            }
        }
        emit()
        server.start(queue: queue)
    }

    func cancel() {
        queue.async { [weak self] in
            guard let self, isClosed == false else { return }
            finish()
            server?.cancel()
            client.cancel()
        }
    }

    private func readHead(from server: NWConnection) {
        server.receive(minimumIncompleteLength: 1, maximumLength: Self.readChunk) { [weak self] data, _, isComplete, error in
            guard let self, isClosed == false else { return }
            if let data {
                head.append(data)
            }
            guard let response = WebSocketHandshake.responseHead(in: head) else {
                if isComplete || error != nil {
                    fail("Upstream closed the connection before it answered the WebSocket handshake.")
                } else if head.count > WebSocketHandshake.maxHeadSize {
                    fail("The upstream answer headers are larger than \(WebSocketHandshake.maxHeadSize) bytes.")
                } else {
                    readHead(from: server)
                }
                return
            }
            answer(response, from: server)
        }
    }

    private func answer(_ response: WebSocketHandshake.ResponseHead, from server: NWConnection) {
        hasAnswered = true
        isOpen = response.status == 101
        exchange.statusCode = response.status
        exchange.statusText = response.reason
        exchange.responseHeaders = response.headers
        exchange.isFailure = isOpen == false
        let bytes = head
        head = Data()
        client.send(content: bytes, completion: .contentProcessed { _ in })
        if isOpen {
            record(Data(bytes.dropFirst(response.length)), isSent: false)
            pump(from: client, to: server, isSent: true)
        }
        emit()
        pump(from: server, to: client, isSent: false)
    }

    private func pump(from source: NWConnection, to destination: NWConnection, isSent: Bool) {
        source.receive(minimumIncompleteLength: 1, maximumLength: Self.readChunk) { [weak self] data, _, isComplete, error in
            guard let self, isClosed == false else { return }
            if let data, data.isEmpty == false {
                destination.send(content: data, completion: .contentProcessed { _ in })
                if isOpen {
                    record(data, isSent: isSent)
                }
            }
            guard isComplete || error != nil else {
                pump(from: source, to: destination, isSent: isSent)
                return
            }
            finish()
            source.cancel()
            destination.send(content: nil, contentContext: .finalMessage, isComplete: true, completion: .contentProcessed { _ in
                destination.cancel()
            })
        }
    }

    private func record(_ data: Data, isSent: Bool) {
        guard data.isEmpty == false else { return }
        let messages = isSent ? sent.append(data) : received.append(data)
        guard messages.isEmpty == false else { return }
        for message in messages {
            transcript.add(message, isSent: isSent)
        }
        scheduleFlush()
    }

    private func scheduleFlush() {
        guard isFlushScheduled == false else { return }
        isFlushScheduled = true
        queue.asyncAfter(deadline: .now() + Self.flushDelay) { [weak self] in
            guard let self else { return }
            isFlushScheduled = false
            guard isClosed == false else { return }
            emit()
        }
    }

    private func fail(_ message: String) {
        guard isClosed == false else { return }
        exchange.error = message
        exchange.isFailure = true
        let client = client
        if hasAnswered {
            client.cancel()
        } else {
            hasAnswered = true
            exchange.statusCode = 502
            exchange.statusText = HTTPResponseSerializer.reasonPhrase(502)
            client.send(content: HTTPResponseSerializer.data(for: .jsonError(502, message)), contentContext: .finalMessage, isComplete: true, completion: .contentProcessed { _ in
                client.cancel()
            })
        }
        finish()
        server?.cancel()
    }

    private func finish() {
        isClosed = true
        let elapsed = clock.now - start
        exchange.duration = Double(elapsed.components.seconds) + Double(elapsed.components.attoseconds) / 1e18
        emit()
        onClose(ObjectIdentifier(self))
    }

    private func emit() {
        exchange.responseBody = transcript.text
        onExchange(NetworkRequestRedactor.redact(exchange))
    }
}
