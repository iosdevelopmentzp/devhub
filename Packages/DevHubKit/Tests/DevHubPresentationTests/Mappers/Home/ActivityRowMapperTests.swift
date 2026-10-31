import DevHubDomain
import DevHubUI
import Foundation
import Testing
@testable import DevHubPresentation

@Suite struct ActivityRowMapperTests {
    @Test func outcomeChoosesDotTintAndOpacity() {
        let table: [(ActivityEvent.Outcome, Tint, Double)] = [
            (.success, .green, 1),
            (.failure, .red, 1),
            (.info, .secondary, 0.5)
        ]

        for (outcome, tint, opacity) in table {
            let model = ActivityRowMapper.model(for: event(outcome), words: .gitHub)
            #expect(model.dotTint == tint)
            #expect(model.dotOpacity == opacity)
        }
    }

    @Test func copiesTitleDetailAndID() {
        let source = event(.success)

        let model = ActivityRowMapper.model(for: source, words: .gitHub)

        #expect(model.id == source.id)
        #expect(model.title == "Build succeeded")
        #expect(model.detail == "ExampleApp · iPhone 16 Pro")
        #expect(model.dateText.isEmpty == false)
        #expect(model.kindTitle == nil)
        #expect(model.target == nil)
        #expect(model.openHint == nil)
    }

    @Test func kindAndTargetGiveTheShortTitleAndTheOpenHint() {
        let source = ActivityEvent(id: UUID(), title: "#12 approved by alex", detail: "ABC-123", date: .now, outcome: .success, kind: .requestReviews, target: .pullRequest(iid: 12))

        let gitHub = ActivityRowMapper.model(for: source, words: .gitHub)
        let gitLab = ActivityRowMapper.model(for: source, words: .gitLab)

        #expect(gitHub.kindTitle == "My PR")
        #expect(gitHub.target == .pullRequest(iid: 12))
        #expect(gitHub.openHint == "Open #12")
        #expect(gitLab.kindTitle == "My MR")
        #expect(gitLab.openHint == "Open !12")
    }

    @Test func everyTargetHasAnOpenHint() {
        #expect(ActivityRowMapper.openHint(for: .reviewQueue, words: .gitHub) == "Open the pull requests that wait for your review")
        #expect(ActivityRowMapper.openHint(for: .worktree(path: "/w"), words: .gitHub) == "Open the Worktrees tab")
        #expect(ActivityRowMapper.openHint(for: .build, words: .gitHub) == "Open the run bar in the Simulators tab")
    }

    private func event(_ outcome: ActivityEvent.Outcome) -> ActivityEvent {
        ActivityEvent(id: UUID(), title: "Build succeeded", detail: "ExampleApp · iPhone 16 Pro", date: Date(timeIntervalSinceNow: -120), outcome: outcome)
    }
}
