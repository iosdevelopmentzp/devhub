import SwiftUI
import DevHubUI

struct CommitFilesList: View {
    let files: CommitRowModel.Files
    let onToggleFile: (_ path: String) -> Void

    var body: some View {
        switch files {
        case .loading:
            ProgressView()
                .controlSize(.small)
                .frame(maxWidth: .infinity)
                .padding(6)
        case .note(let text):
            Text(text)
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 14)
                .padding(.vertical, 4)
        case .loaded(let rows):
            ForEach(rows) { row in
                CommitFileRow(model: row) {
                    onToggleFile(row.path)
                }
            }
        }
    }
}

#Preview {
    CommitFilesList(files: .loaded([.preview]), onToggleFile: { _ in })
        .previewEnvironment()
}
