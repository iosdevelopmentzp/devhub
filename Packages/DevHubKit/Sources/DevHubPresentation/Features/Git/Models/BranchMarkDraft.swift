import Foundation
import DevHubDomain

struct BranchMarkDraft: Equatable {
    var labels: [String]
    var newLabel = ""
    var note: String

    init(mark: BranchMark) {
        labels = mark.labels
        note = mark.note
    }

    var finalLabels: [String] {
        BranchLabelPolicy.merged(labels, adding: BranchLabelPolicy.labels(from: newLabel))
    }

    func options(known: [String]) -> [String] {
        BranchLabelPolicy.merged(known, adding: labels)
    }

    func isSelected(_ label: String) -> Bool {
        labels.contains(label)
    }

    mutating func toggle(_ label: String) {
        if isSelected(label) {
            labels.removeAll { $0 == label }
        } else {
            labels.append(label)
        }
    }

    mutating func addNewLabel() {
        labels = finalLabels
        newLabel = ""
    }
}
