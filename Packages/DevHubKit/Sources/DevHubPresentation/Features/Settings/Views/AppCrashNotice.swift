import SwiftUI
import DevHubDomain
import DevHubUI

struct AppCrashNotice: View {
    let text: String
    let onCopy: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.octagon.fill")
                .foregroundStyle(Tint.red.color)
            Text(text)
                .font(.caption)
                .lineLimit(2)
                .hintWhenTruncated(text)
                .frame(maxWidth: .infinity, alignment: .leading)
            Button("Copy for a Bug Report", action: onCopy)
                .controlSize(.small)
                .fixedSize()
                .hint("Copies the crash report with paths, user and project names replaced")
            IconButton(systemImage: "xmark", help: "Hide this crash until the next one", action: onDismiss)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Tint.red.color.opacity(0.06), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

#Preview {
    AppCrashNotice(text: "DevHub crashed 10 min. ago: EXC_BAD_ACCESS (SIGSEGV) · HomeView.body at HomeView.swift:42", onCopy: {}, onDismiss: {})
        .padding()
        .frame(width: 640)
}
