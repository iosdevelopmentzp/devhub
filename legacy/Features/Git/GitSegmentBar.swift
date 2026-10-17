import SwiftUI

struct GitSegmentBar: View {
    @Environment(GitStore.self) private var store

    private var selection: Binding<GitSegment> {
        Binding(get: { store.segment }, set: { store.selectSegment($0) })
    }

    var body: some View {
        HStack(spacing: 10) {
            Picker("Segment", selection: selection) {
                Text("Local \(store.branches.local.count)").tag(GitSegment.local)
                Text("Remote \(store.branches.remote.count)").tag(GitSegment.remote)
                Text("History").tag(GitSegment.history)
                Text(store.status.isClean ? "Changes" : "Changes \(store.status.changeCount)").tag(GitSegment.changes)
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .fixedSize()
            Spacer(minLength: 8)
            Text(hint)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .padding(.horizontal, 14)
        .padding(.bottom, 10)
    }

    private var hint: String {
        switch store.segment {
        case .local: "Sorted by last checkout"
        case .remote: "Sorted by last commit"
        case .history: "Click a hash to copy it"
        case .changes: "Click a file to see its diff"
        }
    }
}

#Preview {
    GitSegmentBar()
        .previewEnvironment()
}
