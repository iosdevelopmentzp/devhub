import Foundation

enum MergeRequestListStyle: String, CaseIterable {
    case detailed
    case calm
    case compact

    var title: String {
        switch self {
        case .detailed: "Detailed"
        case .calm: "Calm"
        case .compact: "Compact"
        }
    }

    var hint: String {
        switch self {
        case .detailed: "Every fact as a coloured tag"
        case .calm: "The same facts as grey text. Colour only for what needs you: conflicts, a failed pipeline, your review"
        case .compact: "One line per merge request with icons and counts. Click a row to see everything"
        }
    }
}
