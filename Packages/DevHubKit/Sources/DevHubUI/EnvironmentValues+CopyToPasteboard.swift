import SwiftUI

extension EnvironmentValues {
    @Entry package var copyToPasteboard: (_ value: String, _ label: String) -> Void = { _, _ in }
}
