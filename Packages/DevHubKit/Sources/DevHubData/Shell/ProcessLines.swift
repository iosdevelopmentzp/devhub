import Foundation

enum ProcessLines {

    static func lines(of handle: FileHandle) -> AsyncStream<String> {
        AsyncStream { continuation in
            let buffer = LineBuffer()
            handle.readabilityHandler = { handle in
                let chunk = handle.availableData
                guard chunk.isEmpty == false else {
                    handle.readabilityHandler = nil
                    buffer.drain().forEach { continuation.yield($0) }
                    continuation.finish()
                    return
                }
                buffer.append(chunk).forEach { continuation.yield($0) }
            }
            continuation.onTermination = { _ in
                handle.readabilityHandler = nil
            }
        }
    }
}

private final class LineBuffer: @unchecked Sendable {
    private let lock = NSLock()
    private var pending = Data()

    func append(_ chunk: Data) -> [String] {
        lock.withLock {
            pending.append(chunk)
            var lines: [String] = []
            while let newline = pending.firstIndex(of: UInt8(ascii: "\n")) {
                lines.append(Self.text(pending[pending.startIndex..<newline]))
                pending.removeSubrange(pending.startIndex...newline)
            }
            return lines
        }
    }

    func drain() -> [String] {
        lock.withLock {
            defer { pending.removeAll() }
            return pending.isEmpty ? [] : [Self.text(pending)]
        }
    }

    private static func text(_ bytes: Data) -> String {
        let line = String(decoding: bytes, as: UTF8.self)
        return line.hasSuffix("\r") ? String(line.dropLast()) : line
    }
}
