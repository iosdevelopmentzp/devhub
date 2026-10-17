import SwiftUI

struct AIToolbar: View {
    @Environment(AIStore.self) private var store

    let count: Int

    var body: some View {
        @Bindable var store = store
        HStack(spacing: 10) {
            Picker("Provider", selection: $store.providerFilter) {
                ForEach(AIProviderFilter.allCases) { Text($0.title).tag($0) }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .fixedSize()
            Picker("Scope", selection: $store.scope) {
                ForEach(AIScope.allCases) { Text($0.title).tag($0) }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .fixedSize()
            Spacer(minLength: 8)
            Text(count == 1 ? "1 session" : "\(count) sessions")
                .font(.caption)
                .foregroundStyle(.secondary)
            if store.isLoading {
                ProgressView().controlSize(.small)
            }
            IconButton(systemImage: "arrow.clockwise", help: "Read the sessions again") {
                Task { await store.refresh() }
            }
        }
        .controlSize(.small)
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(Theme.base)
    }
}

#Preview {
    AIToolbar(count: 12)
        .previewEnvironment()
}
