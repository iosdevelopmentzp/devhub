import SwiftUI

enum Theme {
    static let base = Color(white: 0.965)
    static let surface = Color.white
    static let border = Color.black.opacity(0.1)
    static let hover = Color.black.opacity(0.05)
    static let shadow = Color.black.opacity(0.08)
    static let bubble = Color(white: 0.12)
}

extension Tint {
    var color: Color {
        switch self {
        case .gray: Color.secondary
        case .red: Color.red
        case .orange: Color.orange
        case .yellow: Color.yellow
        case .green: Color.green
        case .teal: Color.teal
        case .blue: Color.blue
        case .indigo: Color.indigo
        case .purple: Color.purple
        case .pink: Color.pink
        }
    }
}
