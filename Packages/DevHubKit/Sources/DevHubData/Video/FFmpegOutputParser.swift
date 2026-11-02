import Foundation
import DevHubDomain

final class FFmpegOutputParser: @unchecked Sendable {
    private let lock = NSLock()
    private var seconds: Double = 0
    private var speed: Double?
    private var lines: [String] = []

    var messages: [String] {
        lock.withLock { lines }
    }

    func read(_ line: String) -> VideoCompressionProgress? {
        lock.withLock {
            guard let (key, value) = Self.pair(line) else {
                let message = Self.message(line)
                if message.isEmpty == false, lines.last != message {
                    lines.append(message)
                }
                return nil
            }
            switch key {
            case "out_time_us":
                if let microseconds = Double(value) {
                    seconds = microseconds / 1_000_000
                }
            case "speed":
                speed = Double(value.replacingOccurrences(of: "x", with: "").trimmed)
            case "progress":
                return VideoCompressionProgress(seconds: seconds, speed: speed)
            default:
                break
            }
            return nil
        }
    }

    func failure(exitCode: Int32) -> String {
        let last = messages.suffix(3)
        guard last.isEmpty == false else { return "ffmpeg stopped with exit code \(exitCode)." }
        return last.joined(separator: "\n")
    }

    static func message(_ line: String) -> String {
        line.replacingOccurrences(of: #"^\[[^\]]* @ 0x[0-9a-f]+\] "#, with: "", options: .regularExpression).trimmed
    }

    private static func pair(_ line: String) -> (String, String)? {
        guard let equals = line.firstIndex(of: "=") else { return nil }
        let key = line[..<equals]
        guard key.isEmpty == false, key.allSatisfy({ $0.isLowercase || $0.isNumber || $0 == "_" }) else { return nil }
        return (String(key), String(line[line.index(after: equals)...]).trimmed)
    }
}
