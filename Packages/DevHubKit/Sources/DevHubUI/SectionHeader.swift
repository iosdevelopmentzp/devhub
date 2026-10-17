import SwiftUI

package struct SectionHeader<Trailing: View>: View {
    private let title: String
    private let trailing: Trailing

    package init(_ title: String, @ViewBuilder trailing: () -> Trailing) {
        self.title = title
        self.trailing = trailing()
    }

    package var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title.uppercased())
                .font(.caption.weight(.semibold))
                .kerning(0.6)
                .foregroundStyle(.secondary)
            Spacer()
            trailing
        }
    }
}

package extension SectionHeader where Trailing == EmptyView {

    init(_ title: String) {
        self.init(title) { EmptyView() }
    }
}
