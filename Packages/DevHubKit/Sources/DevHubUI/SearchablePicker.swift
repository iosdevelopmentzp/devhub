import SwiftUI

package struct SearchablePicker<Item: Hashable>: View {
    private let title: String
    @Binding private var selection: Item
    private let items: [Item]
    private let label: (Item) -> String
    private let detail: (Item) -> String?
    private var customTrigger: ((Item) -> AnyView)?

    @State private var isOpen = false
    @State private var query = ""
    @State private var highlighted = 0
    @FocusState private var isFocused: Bool

    private static var rowLimit: Int { 200 }

    package init(title: String, selection: Binding<Item>, items: [Item], label: @escaping (Item) -> String, detail: @escaping (Item) -> String?) {
        self.title = title
        _selection = selection
        self.items = items
        self.label = label
        self.detail = detail
        customTrigger = nil
    }

    private var matches: [Item] {
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        guard trimmed.isEmpty == false else { return items }
        return items.filter { label($0).localizedCaseInsensitiveContains(trimmed) }
    }

    package var body: some View {
        trigger
        .fixedSize()
        .hint(title)
        .popover(isPresented: $isOpen, arrowEdge: .bottom) {
            popoverContent
        }
    }

    package func trigger(_ build: @escaping (Item) -> AnyView) -> SearchablePicker {
        var copy = self
        copy.customTrigger = build
        return copy
    }

    @ViewBuilder
    private var trigger: some View {
        if let customTrigger {
            Button {
                isOpen.toggle()
            } label: {
                customTrigger(selection)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        } else {
            Button {
                isOpen.toggle()
            } label: {
                HStack(spacing: 4) {
                    Text(label(selection))
                        .lineLimit(1)
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 9))
                }
            }
            .controlSize(.small)
        }
    }

    private var popoverContent: some View {
        VStack(spacing: 0) {
            TextField("Search \(title.lowercased())", text: $query)
                .textFieldStyle(.roundedBorder)
                .padding(8)
                .focused($isFocused)
                .onChange(of: query) { highlighted = 0 }
                .onKeyPress(.downArrow) { move(1) }
                .onKeyPress(.upArrow) { move(-1) }
                .onKeyPress(.return) { chooseHighlighted() }
                .onKeyPress(.escape) {
                    isOpen = false
                    return .handled
                }
            Divider()
            list
        }
        .frame(width: 280, height: 300)
        .onAppear {
            query = ""
            highlighted = 0
            isFocused = true
        }
    }

    private var list: some View {
        let visible = Array(matches.prefix(Self.rowLimit))
        return ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(visible.indices, id: \.self) { index in
                    row(visible[index], isHighlighted: index == highlighted)
                }
                if matches.count > visible.count {
                    Text("\(matches.count - visible.count) more. Type to narrow the list.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(8)
                }
            }
        }
    }

    private func row(_ item: Item, isHighlighted: Bool) -> some View {
        Button {
            choose(item)
        } label: {
            HStack {
                Text(label(item))
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .frame(maxWidth: .infinity, alignment: .leading)
                if let detail = detail(item) {
                    Text(detail)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                if item == selection {
                    Image(systemName: "checkmark")
                        .font(.caption)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(isHighlighted ? Color.accentColor.opacity(0.12) : .clear)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func move(_ step: Int) -> KeyPress.Result {
        let count = min(matches.count, Self.rowLimit)
        guard count > 0 else { return .handled }
        highlighted = min(max(highlighted + step, 0), count - 1)
        return .handled
    }

    private func chooseHighlighted() -> KeyPress.Result {
        guard matches.indices.contains(highlighted) else { return .handled }
        choose(matches[highlighted])
        return .handled
    }

    private func choose(_ item: Item) {
        selection = item
        isOpen = false
    }
}

package extension SearchablePicker where Item == String {
    init(title: String, selection: Binding<String>, items: [String], detail: @escaping (String) -> String?) {
        self.init(title: title, selection: selection, items: items, label: { $0 }, detail: detail)
    }
}

#Preview {
    @Previewable @State var scheme = "App"
    SearchablePicker(title: "Scheme", selection: $scheme, items: ["App", "Tools", "Widgets"]) { _ in nil }
        .padding()
}
