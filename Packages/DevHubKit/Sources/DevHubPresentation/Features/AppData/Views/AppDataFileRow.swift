import SwiftUI
import DevHubDomain
import DevHubUI

struct AppDataFileRow: View {
    @Environment(AppActions.self) private var appActions

    let model: AppDataFileRowModel

    var body: some View {
        RowContainer(verticalPadding: 4) { isHovered in
            HStack(spacing: 8) {
                Image(systemName: model.icon)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(width: 16)
                Text(model.name)
                    .font(.caption.monospaced())
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .copyOnClick(model.path, label: "Path")
                Spacer(minLength: 8)
                Text(model.sizeText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize()
                IconButton(systemImage: "folder", help: model.hint) {
                    appActions.openInFinder(path: model.path)
                }
                .opacity(isHovered ? 1 : 0)
            }
        }
    }
}

#Preview {
    AppDataFileRow(model: .preview)
        .previewEnvironment()
        .frame(width: 640)
}
