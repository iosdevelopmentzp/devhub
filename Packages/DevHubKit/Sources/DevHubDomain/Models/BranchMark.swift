import Foundation

package struct BranchMark: Hashable, Codable, Sendable {
    package var isPinned = false
    package var labels: [String] = []
    package var note = ""

    package init(isPinned: Bool = false, labels: [String] = [], note: String = "") {
        self.isPinned = isPinned
        self.labels = labels
        self.note = note
    }

    package var isEmpty: Bool {
        isPinned == false && labels.isEmpty && note.isEmpty
    }
}
