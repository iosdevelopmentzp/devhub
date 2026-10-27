import Foundation
import DevHubUI

enum BranchLabelMapper {
    private static let tints: [Tint] = [.blue, .purple, .indigo, .teal, .green, .orange, .pink]

    static func tags(for labels: [String]) -> [TagModel] {
        labels.map { TagModel($0, tint: tint(for: $0), systemImage: "tag") }
    }

    static func tint(for label: String) -> Tint {
        let sum = label.lowercased().unicodeScalars.reduce(0) { $0 + Int($1.value) }
        return tints[sum % tints.count]
    }
}
