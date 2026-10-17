import SwiftUI

struct StatusDot: View {
    let color: Tint

    var body: some View {
        Circle()
            .fill(color.color)
            .frame(width: 7, height: 7)
    }
}

#Preview {
    StatusDot(color: .green)
        .padding()
}
