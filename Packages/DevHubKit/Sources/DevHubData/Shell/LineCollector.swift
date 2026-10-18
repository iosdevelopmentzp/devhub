import Foundation
import DevHubDomain

final class LineCollector: @unchecked Sendable {
    private let lock = NSLock()
    private var lines: [String] = []

    func append(_ line: String) {
        lock.withLock { lines.append(line) }
    }

    var text: String {
        lock.withLock { lines.joined(separator: "\n") }
    }
}
