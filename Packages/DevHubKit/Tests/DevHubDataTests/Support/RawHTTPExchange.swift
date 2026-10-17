import Foundation
import Network

final class RawHTTPExchange: @unchecked Sendable {
    private let lock = NSLock()
    private let connection: NWConnection
    private var continuation: CheckedContinuation<Data, any Error>?
    private var received = Data()

    init(connection: NWConnection) {
        self.connection = connection
    }

    func start(_ request: Data, continuation: CheckedContinuation<Data, any Error>) {
        lock.withLock { self.continuation = continuation }
        connection.stateUpdateHandler = { [self] state in
            switch state {
            case .ready:
                connection.send(content: request, completion: .contentProcessed { _ in })
                receive()
            case .failed(let error), .waiting(let error):
                finish(.failure(error))
            default:
                break
            }
        }
        connection.start(queue: .global())
    }

    private func receive() {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 1 << 16) { [self] data, _, isComplete, error in
            let total = lock.withLock {
                if let data { received.append(data) }
                return received
            }
            if isComplete || error != nil {
                finish(.success(total))
            } else {
                receive()
            }
        }
    }

    private func finish(_ result: Result<Data, any Error>) {
        let pending = lock.withLock {
            defer { continuation = nil }
            return continuation
        }
        connection.cancel()
        pending?.resume(with: result)
    }
}
