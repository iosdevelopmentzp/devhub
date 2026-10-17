import SwiftUI

package extension Tint {

    var color: Color {
        switch self {
        case .green: .green
        case .orange: .orange
        case .yellow: .yellow
        case .red: .red
        case .blue: .blue
        case .purple: .purple
        case .indigo: .indigo
        case .teal: .teal
        case .pink: .pink
        case .gray: .gray
        case .secondary: .secondary
        }
    }
}
