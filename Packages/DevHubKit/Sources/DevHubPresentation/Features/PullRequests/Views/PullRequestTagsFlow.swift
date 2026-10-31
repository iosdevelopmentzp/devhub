import SwiftUI
import DevHubUI

struct PullRequestTagsFlow: View {
    @Environment(AppActions.self) private var appActions

    let model: PullRequestRowModel
    let onLabel: ((String) -> Void)?

    var body: some View {
        FlowLayout(spacing: 6) {
            if let ticket = model.ticket {
                TicketChip(model: ticket)
            }
            if let pipeline = model.pipelineTag {
                Button {
                    appActions.open(model.pipelineURL)
                } label: {
                    ModelTag(model: pipeline)
                }
                .buttonStyle(.plain)
            }
            ForEach(model.tags, id: \.self) { tag in
                ModelTag(model: tag, isPlain: model.usesPlainTags)
            }
            ForEach(model.labelTags, id: \.self) { tag in
                if let onLabel {
                    Button {
                        onLabel(tag.text)
                    } label: {
                        ModelTag(model: tag, isPlain: model.usesPlainTags)
                    }
                    .buttonStyle(.plain)
                } else {
                    ModelTag(model: tag, isPlain: model.usesPlainTags)
                }
            }
        }
    }
}

#Preview {
    PullRequestTagsFlow(model: .preview, onLabel: { _ in })
        .previewEnvironment()
        .padding()
        .frame(width: 560)
}
