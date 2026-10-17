import Foundation

package struct GitDiff: Hashable, Sendable {
    package let lines: [String]
    package let droppedLines: Int
    package let isBinary: Bool

    package init(lines: [String], droppedLines: Int, isBinary: Bool) {
        self.lines = lines
        self.droppedLines = droppedLines
        self.isBinary = isBinary
    }
}
