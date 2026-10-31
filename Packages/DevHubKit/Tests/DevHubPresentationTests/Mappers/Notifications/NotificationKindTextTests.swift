import DevHubDomain
import Testing
@testable import DevHubPresentation

@Suite struct NotificationKindTextTests {
    @Test func everyKindHasATitleADescriptionAndAShortTitle() {
        for kind in NotificationKind.allCases {
            for words in [CodeHostWords.gitHub, .gitLab] {
                #expect(NotificationKindText.title(for: kind, words: words).isEmpty == false)
                #expect(NotificationKindText.description(for: kind, words: words).contains("A click") || kind == .scripts)
                #expect(NotificationKindText.shortTitle(for: kind, words: words).count <= 6)
            }
        }
    }

    @Test func requestKindsUseTheWordsOfTheHost() {
        #expect(NotificationKindText.title(for: .requestChecks, words: .gitHub) == "Checks of my pull requests")
        #expect(NotificationKindText.title(for: .requestChecks, words: .gitLab) == "Pipeline of my merge requests")
        #expect(NotificationKindText.title(for: .reviewRequests, words: .gitLab) == "Merge Requests waiting for your review")
        #expect(NotificationKindText.description(for: .requestReviews, words: .gitHub) == "Someone approved your pull request or asked for changes. A click opens the pull request.")
        #expect(NotificationKindText.shortTitle(for: .requestClosed, words: .gitLab) == "My MR")
    }

    @Test func filterTitlesReadAsASentencePart() {
        #expect(NotificationKindText.filterTitle(for: .all, words: .gitHub) == "all events")
        #expect(NotificationKindText.filterTitle(for: .kind(.build), words: .gitHub) == "builds")
        #expect(NotificationKindText.filterTitle(for: .other, words: .gitHub) == "other events")
    }
}
