import SwiftUI

package struct KeyValueBlock: View {
    private let pairs: [(String, String)]

    package init(pairs: [(String, String)]) {
        self.pairs = pairs
    }

    package var body: some View {
        Grid(alignment: .leadingFirstTextBaseline, horizontalSpacing: 12, verticalSpacing: 4) {
            ForEach(pairs.indices, id: \.self) { index in
                GridRow {
                    Text(pairs[index].0)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(pairs[index].1)
                        .font(.caption)
                        .textSelection(.enabled)
                }
            }
        }
    }
}

#Preview {
    KeyValueBlock(pairs: [("Version", "1.2"), ("Build", "42")])
        .padding()
}
