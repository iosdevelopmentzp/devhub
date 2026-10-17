import SwiftUI

package struct NoticeBar: View {
    package let text: String
    package let systemImage: String
    package let tint: Color
    package let actionTitle: String?
    package let action: (() -> Void)?

    package init(_ text: String, systemImage: String = "exclamationmark.triangle.fill", tint: Color = .red, actionTitle: String?, action: (() -> Void)?) {
        self.text = text
        self.systemImage = systemImage
        self.tint = tint
        self.actionTitle = actionTitle
        self.action = action
    }

    package var body: some View {
        HStack(spacing: 8) {
            Image(systemName: systemImage)
                .foregroundStyle(tint)
            Text(text)
                .font(.caption)
                .lineLimit(2)
                .hintWhenTruncated(text)
                .frame(maxWidth: .infinity, alignment: .leading)
            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .controlSize(.small)
                    .fixedSize()
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 6)
        .background(tint.opacity(0.06))
    }
}

#Preview {
    NoticeBar("Cannot read merge requests: glab exited with code 1", actionTitle: "Retry", action: {})
        .frame(width: 640)
}
