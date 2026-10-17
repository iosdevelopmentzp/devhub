import SwiftUI

struct GitOperationBanner: View {
    @Environment(GitStore.self) private var store

    let operation: GitOperation

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(Tint.orange.color)
            Text("\(operation.title) in progress")
                .font(.callout.weight(.medium))
                .frame(maxWidth: .infinity, alignment: .leading)
            Button("Continue") { Task { await store.continueOperation() } }
            Button("Abort") { Task { await store.abortOperation() } }
            Button("Terminal") { store.openTerminal() }
        }
        .controlSize(.small)
        .fixedSize(horizontal: false, vertical: true)
        .padding(8)
        .background(Tint.orange.color.opacity(0.12), in: RoundedRectangle(cornerRadius: 8))
        .disabled(store.isBusy)
    }
}

#Preview {
    GitOperationBanner(operation: .rebase)
        .padding()
        .previewEnvironment()
}
