import Foundation
import DevHubDomain
import DevHubUI

enum ConfigTintMapper {
    static func tint(_ tint: ConfigTint?) -> Tint {
        switch tint {
        case .gray, nil: .gray
        case .red: .red
        case .orange: .orange
        case .yellow: .yellow
        case .green: .green
        case .teal: .teal
        case .blue: .blue
        case .indigo: .indigo
        case .purple: .purple
        case .pink: .pink
        }
    }
}
