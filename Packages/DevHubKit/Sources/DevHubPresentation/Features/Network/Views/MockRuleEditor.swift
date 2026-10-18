import SwiftUI
import DevHubDomain
import DevHubUI

struct MockRuleEditor: View {
    let rule: MockRule
    let onSave: (MockRule) -> Void
    let onCancel: () -> Void

    @State private var draft: MockRuleDraft

    init(rule: MockRule, onSave: @escaping (MockRule) -> Void, onCancel: @escaping () -> Void) {
        self.rule = rule
        self.onSave = onSave
        self.onCancel = onCancel
        _draft = State(initialValue: MockRuleDraft(rule: rule))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                FieldLabel("Request")
                Picker("Method", selection: $draft.method) {
                    ForEach(MockRuleDraft.methods, id: \.self) { method in
                        Text(method).tag(method)
                    }
                }
                .labelsHidden()
                .fixedSize()
                TextField("/v1/path, * for one segment, ** for any", text: $draft.path)
                    .font(.callout.monospaced())
                    .textFieldStyle(.roundedBorder)
                    .hint("Exact path, or a pattern: * matches one segment, ** matches any number of segments")
                TextField("query (optional)", text: $draft.query)
                    .font(.callout.monospaced())
                    .textFieldStyle(.roundedBorder)
                    .frame(maxWidth: 160)
                    .hint("Every key=value pair here must be in the request query. A key without a value only has to be present.")
            }
            HStack(spacing: 8) {
                FieldLabel("GraphQL")
                TextField("operation name (optional), * allowed", text: $draft.operationName)
                    .font(.callout.monospaced())
                    .textFieldStyle(.roundedBorder)
                    .hint("The rule matches only a GraphQL request with this operation name, for example GetProfile or Get*. Leave it empty for REST.")
            }
            HStack(spacing: 8) {
                FieldLabel("Action")
                Picker("Action", selection: $draft.kind) {
                    ForEach(MockRuleDraft.Kind.allCases) { kind in
                        Text(kind.title).tag(kind)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .fixedSize()
                Spacer(minLength: 6)
                Text("Delay, ms")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                TextField("0", text: $draft.delayMilliseconds)
                    .font(.callout.monospaced())
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 64)
            }
            switch draft.kind {
            case .respond:
                respondFields
            case .patch:
                patchFields
            }
            HStack(spacing: 8) {
                if let error = draft.validationError {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 6)
                Button("Cancel", action: onCancel)
                    .fixedSize()
                Button("Save Rule") {
                    guard let saved = draft.rule(id: rule.id, isEnabled: rule.isEnabled) else { return }
                    onSave(saved)
                }
                .buttonStyle(.borderedProminent)
                .fixedSize()
                .disabled(draft.validationError != nil)
            }
        }
        .controlSize(.small)
        .padding(.leading, 56)
        .padding(.trailing, 14)
        .padding(.vertical, 10)
        .background(Theme.base)
    }

    private var respondFields: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                FieldLabel("Status")
                TextField("200", text: $draft.status)
                    .font(.callout.monospaced())
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 64)
                Text("Content-Type")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                TextField("application/json", text: $draft.contentType)
                    .font(.callout.monospaced())
                    .textFieldStyle(.roundedBorder)
            }
            editor(text: $draft.body, height: 160)
        }
    }

    private var patchFields: some View {
        VStack(alignment: .leading, spacing: 4) {
            editor(text: $draft.patchLines, height: 100)
            Text("One change per line: data.profile.isVIP = true, or remove data.banner. Use [0] for array items. Values are JSON; other text becomes a string.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func editor(text: Binding<String>, height: CGFloat) -> some View {
        PlainTextEditor(text: text)
            .padding(4)
            .frame(height: height)
            .background(Theme.surface, in: RoundedRectangle(cornerRadius: 6, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 6, style: .continuous).stroke(Theme.border))
    }
}

#Preview {
    MockRuleEditor(rule: MockRuleFactory.newRule(id: UUID()), onSave: { _ in }, onCancel: {})
        .previewEnvironment()
        .frame(width: 720)
}
