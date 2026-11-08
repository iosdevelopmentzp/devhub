import SwiftUI
import DevHubDomain

struct DiffFontSizeModifier: ViewModifier {
    let settings: SettingsStore

    func body(content: Content) -> some View {
        content.environment(\.diffFontSize, CGFloat(settings.values.diffFontSize))
    }
}
