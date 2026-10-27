import SwiftUI
import DevHubUI

struct KeepAwakeCard: View {
    let model: KeepAwakeCardModel
    let toggle: () -> Void

    var body: some View {
        PanelCard {
            HStack(spacing: 10) {
                IconTile(systemImage: model.systemImage, tint: model.tint.color, size: 28)
                VStack(alignment: .leading, spacing: 2) {
                    Text(model.title)
                        .font(.callout.weight(.semibold))
                    Text(model.subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .hintWhenTruncated(model.subtitle)
                }
                Spacer(minLength: 0)
                Toggle(model.title, isOn: isOn)
                    .toggleStyle(.switch)
                    .controlSize(.small)
                    .labelsHidden()
            }
        }
    }

    private var isOn: Binding<Bool> {
        Binding(
            get: { model.isActive },
            set: { _ in toggle() }
        )
    }
}

#Preview {
    KeepAwakeCard(model: .preview) {}
        .frame(width: 420)
        .padding()
}
