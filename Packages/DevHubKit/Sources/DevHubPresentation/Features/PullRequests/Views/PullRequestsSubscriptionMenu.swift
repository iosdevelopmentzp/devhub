import SwiftUI
import DevHubDomain
import DevHubUI

struct PullRequestsSubscriptionMenu: View {
    @Environment(PullRequestSubscriptionsStore.self) private var subscriptions
    @Environment(AppActions.self) private var appActions
    @Environment(\.codeHostWords) private var words

    var body: some View {
        let toUnsubscribe = subscriptions.othersToUnsubscribe.count
        let toSubscribe = subscriptions.toSubscribeAgain.count
        Menu {
            Button("Unsubscribe from All by Others (\(toUnsubscribe))", systemImage: "speaker.slash") { appActions.unsubscribeFromOthers() }
                .disabled(toUnsubscribe == 0)
            Button("Subscribe Again (\(toSubscribe))", systemImage: "speaker.wave.2") { appActions.subscribeAgain() }
                .disabled(toSubscribe == 0)
        } label: {
            if subscriptions.isBulkRunning {
                ProgressView()
                    .controlSize(.mini)
            } else {
                Image(systemName: toSubscribe == 0 ? "speaker.wave.2" : "speaker.slash")
                    .foregroundStyle(toSubscribe == 0 ? Color.secondary : Color.accentColor)
            }
        }
        .menuStyle(.borderlessButton)
        .menuIndicator(.hidden)
        .fixedSize()
        .disabled(subscriptions.isBulkRunning)
        .hint("Notifications of \(words.hostTitle). Unsubscribe from every open \(words.request) by other people, or subscribe again to the ones DevHub unsubscribed. Your own \(words.requests) stay as they are. One \(words.request): its row menu.")
    }
}

#Preview {
    PullRequestsSubscriptionMenu()
        .previewEnvironment()
        .padding()
}
