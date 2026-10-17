import SwiftUI
import DevHubDomain
import DevHubUI

struct CleanInstallNote: View {
    let model: CleanInstallNoteModel

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            Image(systemName: model.icon)
                .foregroundStyle(model.iconTint.color)
            Text(model.text)
                .fixedSize(horizontal: false, vertical: true)
        }
        .font(.caption2)
        .foregroundStyle(.secondary)
    }
}

#Preview {
    CleanInstallNote(model: .preview)
        .padding()
}
