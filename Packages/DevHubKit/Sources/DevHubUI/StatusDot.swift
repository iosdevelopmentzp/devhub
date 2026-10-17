import SwiftUI

package struct StatusDot: View {
    package let color: Color

    package init(color: Color) {
        self.color = color
    }

    package var body: some View {
        Circle()
            .fill(color)
            .frame(width: 7, height: 7)
    }
}
