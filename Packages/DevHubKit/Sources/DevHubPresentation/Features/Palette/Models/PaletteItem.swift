import Foundation
import DevHubDomain
import DevHubUI

struct PaletteItem: Identifiable, Hashable {
    let id: String
    let title: String
    let subtitle: String
    let systemImage: String
    let section: String
    let command: PaletteCommand
}
