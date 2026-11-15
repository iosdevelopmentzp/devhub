import SwiftUI
import DevHubDomain
import DevHubUI

struct TicketDetailsView: View {
    @Environment(AppActions.self) private var appActions

    let model: TicketDetailsModel
    let url: URL?
    let isBusy: Bool
    let canAssignToMe: Bool
    let onAssignToMe: () -> Void
    let onSend: (String) async -> Bool

    @State private var draft = ""
    @State private var isComposing = false
    @FocusState private var isDraftFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            description
            if model.facts.isEmpty == false || model.labels.isEmpty == false || model.components.isEmpty == false {
                facts
            }
            if let parent = model.parent {
                section("Parent") {
                    TicketLinkRow(model: parent)
                }
            }
            if model.subtasks.isEmpty == false {
                section("Sub-tasks") {
                    ForEach(model.subtasks) { TicketLinkRow(model: $0) }
                }
            }
            comments
            footer
        }
        .padding(.leading, 56)
        .padding(.trailing, 14)
        .padding(.top, 2)
        .padding(.bottom, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .animation(.snappy(duration: 0.18), value: isComposing)
    }

    @ViewBuilder
    private var description: some View {
        if let text = model.description {
            ExpandableText(AttributedString(text), lineLimit: 8)
                .font(.callout)
                .textSelection(.enabled)
        } else {
            Text("No description")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var facts: some View {
        FlowLayout(spacing: 6) {
            ForEach(model.facts, id: \.self) { fact in
                Text(fact)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            ForEach(model.labels, id: \.self) { label in
                Tag(label, tint: .secondary, systemImage: "tag")
            }
            ForEach(model.components, id: \.self) { component in
                Tag(component, tint: Tint.indigo.color, systemImage: "square.stack.3d.up")
            }
        }
    }

    @ViewBuilder
    private var comments: some View {
        if model.comments.isEmpty == false {
            section("Comments") {
                if let earlier = model.earlierCommentsText {
                    Button(earlier) { appActions.open(url) }
                        .buttonStyle(LinkButtonStyle(.accent))
                        .disabled(url == nil)
                }
                ForEach(model.comments) { comment in
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 6) {
                            Text(comment.author)
                                .font(.caption.weight(.semibold))
                            if let date = comment.dateText {
                                Text(date)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        ExpandableText(AttributedString(comment.body), lineLimit: 4)
                            .font(.caption)
                            .textSelection(.enabled)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var footer: some View {
        if isComposing {
            VStack(alignment: .leading, spacing: 6) {
                TextField("Write a comment", text: $draft, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(2...6)
                    .focused($isDraftFocused)
                    .disabled(isBusy)
                HStack(spacing: 8) {
                    Button("Send") { send() }
                        .keyboardShortcut(.return, modifiers: .command)
                        .disabled(isBusy || draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        .fixedSize()
                    Button("Cancel") {
                        isComposing = false
                        draft = ""
                    }
                    .keyboardShortcut(.cancelAction)
                    .disabled(isBusy)
                    .fixedSize()
                    if isBusy {
                        ProgressView()
                            .controlSize(.small)
                    }
                    Text("⌘↩ sends")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        } else {
            HStack(spacing: 8) {
                Button("Add Comment", systemImage: "text.bubble") {
                    isComposing = true
                    Task { isDraftFocused = true }
                }
                .fixedSize()
                if canAssignToMe {
                    Button("Assign to Me", systemImage: "person.crop.circle.badge.checkmark", action: onAssignToMe)
                        .disabled(isBusy)
                        .fixedSize()
                }
                Button("Open in Browser", systemImage: "safari") { appActions.open(url) }
                    .disabled(url == nil)
                    .fixedSize()
            }
            .controlSize(.small)
        }
    }

    private func section(_ title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            content()
        }
    }

    private func send() {
        let text = draft
        Task {
            guard await onSend(text) else { return }
            draft = ""
            isComposing = false
        }
    }
}

#Preview {
    TicketDetailsView(model: .preview, url: nil, isBusy: false, canAssignToMe: true, onAssignToMe: {}, onSend: { _ in true })
        .previewEnvironment()
}
