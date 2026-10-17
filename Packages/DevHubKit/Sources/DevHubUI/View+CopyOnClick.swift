import SwiftUI

package extension View {

    func copyOnClick(_ value: String, label: String) -> some View {
        modifier(CopyOnClick(value: value, label: label))
    }
}
