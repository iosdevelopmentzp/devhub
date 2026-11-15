import SwiftUI
import DevHubDomain
import DevHubUI

struct TicketDetailsView: View {
    @Environment(AppActions.self) private var appActions
    @Environment(Toaster.self) private var toaster

    let model: TicketDetailsModel
    let url: URL?
    let isBusy: Bool
    let canAssignToMe: Bool
    let canWatch: Bool
    let onAssignToMe: () -> Void
    let onWatch: () -> Void
    let onSend: (String) async -> Bool

    @State private var draft = ""
    @State private var isComposing = false
    @State private var showsAllComments = false
    @FocusState private var isDraftFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            description
            if model.hasFacts {
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
            if model.links.isEmpty == false {
                section("Links") {
                    ForEach(model.links) { TicketLinkRow(model: $0) }
                }
            }
            lines
            comments
            footer
        }
        .padding(.leading, 56)
        .padding(.trailing, 14)
        .padding(.top, 2)
        .padding(.bottom, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .animation(.snappy(duration: 0.18), value: isComposing)
        .animation(.snappy(duration: 0.18), value: showsAllComments)
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
            if let due = model.dueTag {
                ModelTag(model: due)
            }
            ForEach(model.labels, id: \.self) { label in
                Tag(label, tint: .secondary, systemImage: "tag")
            }
            ForEach(model.components, id: \.self) { component in
                Tag(component, tint: Tint.indigo.color, systemImage: "square.stack.3d.up")
            }
            ForEach(model.fixVersions, id: \.self) { version in
                Tag(version, tint: Tint.teal.color, systemImage: "shippingbox")
                    .hint("Fix version")
            }
        }
    }

    @ViewBuilder
    private var lines: some View {
        if let time = model.timeText {
            line(time, systemImage: "clock")
        }
        if let attachments = model.attachmentsText {
            line(attachments, systemImage: "paperclip")
        }
        if let watchers = model.watchersText {
            line(watchers, systemImage: model.isWatching ? "eye.fill" : "eye")
        }
    }

    private func line(_ text: String, systemImage: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            Image(systemName: systemImage)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .frame(width: 12)
            Text(text)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)
                .textSelection(.enabled)
        }
    }

    @ViewBuilder
    private var comments: some View {
        if model.comments.isEmpty == false {
            section("Comments") {
                if let earlier = model.earlierCommentsTitle, showsAllComments == false {
                    Button(earlier) { showsAllComments = true }
                        .buttonStyle(LinkButtonStyle(.accent))
                }
                ForEach(showsAllComments ? model.comments : model.recentComments) { comment in
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
            ActionBar(items: actions)
                .controlSize(.small)
        }
    }

    private var actions: [ActionItem] {
        var items: [ActionItem] = [
            ActionItem("Add Comment", systemImage: "text.bubble", hint: "Write a comment. jira issue comment add", priority: 5, isDisabled: false) {
                isComposing = true
                Task { isDraftFocused = true }
            },
        ]
        if canAssignToMe {
            items.append(ActionItem("Assign to Me", systemImage: "person.crop.circle.badge.checkmark", hint: "jira issue assign", priority: 4, isDisabled: isBusy, action: onAssignToMe))
        }
        if canWatch && model.isWatching == false {
            items.append(ActionItem("Watch", systemImage: "eye", hint: "Get Jira mail about this ticket. jira issue watch", priority: 3, isDisabled: isBusy, action: onWatch))
        }
        if let url {
            items.append(ActionItem("Copy Link", systemImage: "link", hint: url.absoluteString, priority: 1, isDisabled: false) { toaster.copy(url.absoluteString, label: "link") })
        }
        items.append(ActionItem("Open in Browser", systemImage: "safari", hint: "Open the ticket in the browser", priority: 2, isDisabled: url == nil) { appActions.open(url) })
        return items
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
    TicketDetailsView(model: .preview, url: nil, isBusy: false, canAssignToMe: true, canWatch: true, onAssignToMe: {}, onWatch: {}, onSend: { _ in true })
        .previewEnvironment()
}
