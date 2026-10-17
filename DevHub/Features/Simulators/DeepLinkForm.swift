import SwiftUI

struct DeepLinkForm: View {
    @Environment(SimulatorsStore.self) private var store

    let simulator: SimulatorInfo

    @State private var link = ""
    @State private var isSending = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                TextField("myapp://path or https://…", text: $link)
                    .textFieldStyle(.roundedBorder)
                    .font(.callout.monospaced())
                    .onSubmit(send)
                Button("Open", action: send)
                    .buttonStyle(.borderedProminent)
                    .disabled(link.trimmingCharacters(in: .whitespaces).isEmpty || isSending)
            }
            .controlSize(.small)
            if store.recentLinks.isEmpty == false {
                Text("RECENT")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                ForEach(store.recentLinks, id: \.self) { recent in
                    HStack(spacing: 6) {
                        Button {
                            link = recent
                        } label: {
                            Text(recent)
                                .font(.caption.monospaced())
                                .lineLimit(1)
                                .truncationMode(.middle)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .buttonStyle(.plain)
                        IconButton(systemImage: "xmark", help: "Forget this link") { store.forgetLink(recent) }
                    }
                }
            }
        }
    }

    private func send() {
        guard isSending == false else { return }
        isSending = true
        Task {
            _ = await store.openLink(link, on: simulator)
            isSending = false
        }
    }
}

#Preview {
    DeepLinkForm(simulator: SimulatorInfo(id: "A", name: "iPhone 17", runtime: "iOS 26.0", state: .booted, appCount: 1, isFavorite: false))
        .padding()
        .previewEnvironment()
}
