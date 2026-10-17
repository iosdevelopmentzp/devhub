import SwiftUI

package struct ExpandableText: View {
    package let text: AttributedString
    package let lineLimit: Int

    @State private var isExpanded = false
    @State private var limitedHeight: CGFloat = 0
    @State private var fullHeight: CGFloat = 0

    package init(_ text: AttributedString, lineLimit: Int) {
        self.text = text
        self.lineLimit = lineLimit
    }

    package var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(text)
                .lineLimit(isExpanded ? nil : lineLimit)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
                .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { limitedHeight = $0 }
                .background {
                    Text(text)
                        .fixedSize(horizontal: false, vertical: true)
                        .hidden()
                        .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { fullHeight = $0 }
                }
            if isExpanded || isTruncated {
                Button(isExpanded ? "Show less" : "Show all") {
                    isExpanded.toggle()
                }
                .buttonStyle(.link)
                .font(.caption)
            }
        }
    }

    private var isTruncated: Bool {
        fullHeight > limitedHeight + 0.5
    }
}

#Preview {
    ExpandableText(AttributedString((1...20).map { "Line \($0)" }.joined(separator: "\n")), lineLimit: 5)
        .font(.callout)
        .padding()
        .frame(width: 400)
}
