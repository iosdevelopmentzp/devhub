import Foundation
import DevHubDomain

struct WebSocketTranscript {
    static let maxLines = 500
    static let maxLineLength = 2_000

    private(set) var lines: [String] = []
    private(set) var count = 0

    mutating func add(_ message: WebSocketMessage, isSent: Bool) {
        let arrow = isSent ? "→" : "←"
        let text: String
        switch message {
        case .ping, .pong:
            return
        case let .text(value):
            text = value
        case let .binary(size):
            text = "<\(size) bytes of binary data>"
        case let .close(code):
            text = code.map { "close \($0)" } ?? "close"
        }
        let line = "\(arrow) \(text.count > Self.maxLineLength ? String(text.prefix(Self.maxLineLength)) + " …" : text)"
        lines.append(line)
        count += 1
        if lines.count > Self.maxLines {
            lines.removeFirst(lines.count - Self.maxLines)
        }
    }

    var text: String {
        let hidden = count - lines.count
        let head = hidden > 0 ? ["… \(hidden) earlier messages are not shown"] : []
        return (head + lines).joined(separator: "\n")
    }
}
