import Foundation
import DevHubDomain

struct ScriptNetworkSourceRepository: NetworkSourceRepository {
    static let firstID = 1 << 40

    let scripts: any ScriptRunning

    func follow(_ request: ScriptRunRequest) -> AsyncThrowingStream<NetworkSourceEvent, any Error> {
        let scripts = scripts
        return AsyncThrowingStream { continuation in
            let task = Task {
                var ids = NetworkSourceIDs(next: Self.firstID)
                do {
                    for try await event in scripts.run(request) {
                        switch event {
                        case let .output(line):
                            continuation.yield(Self.event(for: line, ids: &ids))
                        case let .exited(code):
                            continuation.yield(.exited(code))
                        }
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    private static func event(for line: String, ids: inout NetworkSourceIDs) -> NetworkSourceEvent {
        switch NetworkSourceLineParser.parse(line, id: { ids.id(for: $0) }) {
        case let .request(request): .request(request)
        case let .error(message): .error(LogRedactor.redact(message))
        case .other: .output(LogRedactor.redact(line))
        }
    }
}

private struct NetworkSourceIDs {
    var next: Int
    var known: [String: Int] = [:]

    mutating func id(for key: String?) -> Int {
        if let key, let id = known[key] {
            return id
        }
        defer { next += 1 }
        if let key {
            known[key] = next
        }
        return next
    }
}
