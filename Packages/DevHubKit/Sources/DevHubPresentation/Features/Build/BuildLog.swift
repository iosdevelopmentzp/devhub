import Foundation

struct BuildLog {
    let maxLines: Int
    let trimSlack: Int
    private(set) var lines: [String] = []

    init(maxLines: Int, trimSlack: Int) {
        self.maxLines = maxLines
        self.trimSlack = trimSlack
    }

    mutating func append(_ line: String) {
        lines.append(line)
        guard lines.count > maxLines + trimSlack else { return }
        lines.removeFirst(lines.count - maxLines)
    }

    mutating func removeAll() {
        lines.removeAll()
    }
}
