import SwiftUI
import DevHubDomain
import DevHubUI

struct PullRequestsMuteMenu: View {
    @Environment(OpenPullRequestsStore.self) private var openPullRequests
    @Environment(AppActions.self) private var appActions
    @Environment(\.codeHostWords) private var words

    var body: some View {
        let toMute = openPullRequests.othersToMuteCount
        let muted = openPullRequests.mutedIDs.count
        Menu {
            Button("Mute All Opened by Others (\(toMute))", systemImage: "speaker.slash") { appActions.muteOthers() }
                .disabled(toMute == 0)
            Button("Unmute All (\(muted))", systemImage: "speaker.wave.2") { appActions.unmuteAll() }
                .disabled(muted == 0)
        } label: {
            Image(systemName: muted == 0 ? "speaker.wave.2" : "speaker.slash")
                .foregroundStyle(muted == 0 ? Color.secondary : Color.accentColor)
        }
        .menuStyle(.borderlessButton)
        .menuIndicator(.hidden)
        .fixedSize()
        .hint("Mute or unmute the notifications of open \(words.requests) by other people. Your own \(words.requests) are never muted. One \(words.request): its row menu.")
    }
}

#Preview {
    PullRequestsMuteMenu()
        .previewEnvironment()
        .padding()
}
