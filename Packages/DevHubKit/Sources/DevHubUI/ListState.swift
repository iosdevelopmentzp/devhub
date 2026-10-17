import SwiftUI

package struct ListState<Content: View>: View {
    private let failure: ListMessage?
    private let isLoading: Bool
    private let loadingTitle: String
    private let empty: ListMessage?
    private let searchText: String?
    private let content: Content

    package init(
        failure: ListMessage?,
        isLoading: Bool,
        loadingTitle: String,
        empty: ListMessage?,
        noResultsFor searchText: String?,
        @ViewBuilder content: () -> Content
    ) {
        self.failure = failure
        self.isLoading = isLoading
        self.loadingTitle = loadingTitle
        self.empty = empty
        self.searchText = searchText
        self.content = content()
    }

    package var body: some View {
        if let failure {
            unavailable(failure)
        } else if isLoading {
            ProgressView(loadingTitle)
                .controlSize(.small)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if let empty {
            unavailable(empty)
        } else if let searchText {
            ContentUnavailableView.search(text: searchText)
        } else {
            content
        }
    }

    @ViewBuilder
    private func unavailable(_ message: ListMessage) -> some View {
        if let actionTitle = message.actionTitle, let action = message.action {
            ContentUnavailableView {
                Label(message.title, systemImage: message.systemImage)
            } description: {
                Text(message.description)
            } actions: {
                Button(actionTitle, action: action)
            }
        } else {
            ContentUnavailableView {
                Label(message.title, systemImage: message.systemImage)
            } description: {
                Text(message.description)
            }
        }
    }
}

#Preview("Failure") {
    ListState(
        failure: .failure("Cannot read worktrees", description: "git worktree list failed") {},
        isLoading: false,
        loadingTitle: "Reading worktrees…",
        empty: nil,
        noResultsFor: nil
    ) {
        Text("Content")
    }
    .frame(width: 480, height: 320)
}

#Preview("Loading") {
    ListState(failure: nil, isLoading: true, loadingTitle: "Reading worktrees…", empty: nil, noResultsFor: nil) {
        Text("Content")
    }
    .frame(width: 480, height: 320)
}

#Preview("No results") {
    ListState(failure: nil, isLoading: false, loadingTitle: "", empty: nil, noResultsFor: "ABC-26") {
        Text("Content")
    }
    .frame(width: 480, height: 320)
}
