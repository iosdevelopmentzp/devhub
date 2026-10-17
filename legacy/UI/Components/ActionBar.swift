import SwiftUI

struct ActionItem: Identifiable {
    let id = UUID()
    let title: String
    let systemImage: String
    let hint: String
    let priority: Int
    let isDisabled: Bool
    let action: () -> Void

    init(_ title: String, systemImage: String, hint: String, priority: Int, isDisabled: Bool, action: @escaping () -> Void) {
        self.title = title
        self.systemImage = systemImage
        self.hint = hint
        self.priority = priority
        self.isDisabled = isDisabled
        self.action = action
    }
}

struct ActionBar: View {
    let items: [ActionItem]

    private var priorities: [Int] {
        Array(Set(items.map(\.priority))).sorted()
    }

    var body: some View {
        ViewThatFits(in: .horizontal) {
            row(collapsingUpTo: Int.min)
            row(collapsingUpTo: priority(at: 0))
            row(collapsingUpTo: priority(at: 1))
            row(collapsingUpTo: priority(at: 2))
            row(collapsingUpTo: Int.max)
        }
    }

    private func priority(at index: Int) -> Int {
        guard priorities.isEmpty == false else { return Int.max }
        return priorities[min(index, priorities.count - 1)]
    }

    private func row(collapsingUpTo threshold: Int) -> some View {
        HStack(spacing: 6) {
            ForEach(items) { item in
                button(for: item, iconOnly: item.priority <= threshold)
            }
        }
    }

    @ViewBuilder
    private func button(for item: ActionItem, iconOnly: Bool) -> some View {
        Button(action: item.action) {
            if iconOnly {
                Image(systemName: item.systemImage)
            } else {
                Label(item.title, systemImage: item.systemImage)
            }
        }
        .buttonStyle(.bordered)
        .controlSize(.small)
        .disabled(item.isDisabled)
        .fixedSize()
        .hint(iconOnly ? "\(item.title): \(item.hint)" : item.hint)
    }
}

#Preview {
    ActionBar(items: [
        ActionItem("Fetch", systemImage: "arrow.down.circle", hint: "git fetch", priority: 1, isDisabled: false) {},
        ActionItem("Push", systemImage: "arrow.up", hint: "git push", priority: 2, isDisabled: false) {}
    ])
    .padding()
    .previewEnvironment()
}
