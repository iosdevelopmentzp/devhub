import Foundation

enum DiffLayout: String, CaseIterable, Identifiable {
    case unified
    case sideBySide

    var id: String { rawValue }

    var title: String {
        switch self {
        case .unified: "Unified"
        case .sideBySide: "Side by Side"
        }
    }

    var icon: String {
        switch self {
        case .unified: "text.alignleft"
        case .sideBySide: "rectangle.split.2x1"
        }
    }

    var hint: String {
        switch self {
        case .unified: "Unified: removed and added lines follow each other in one column"
        case .sideBySide: "Side by side: the file before the change on the left, after it on the right"
        }
    }
}
