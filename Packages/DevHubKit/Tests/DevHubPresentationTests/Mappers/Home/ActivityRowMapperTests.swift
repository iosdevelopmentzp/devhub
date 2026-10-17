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
            let model = ActivityRowMapper.model(for: event(outcome))
            #expect(model.dotTint == tint)
            #expect(model.dotOpacity == opacity)
        }
    }

    @Test func copiesTitleDetailAndID() {
        let source = event(.success)

        let model = ActivityRowMapper.model(for: source)

        #expect(model.id == source.id)
        #expect(model.title == "Build succeeded")
        #expect(model.detail == "ExampleApp · iPhone 16 Pro")
        #expect(model.dateText.isEmpty == false)
    }

    private func event(_ outcome: ActivityEvent.Outcome) -> ActivityEvent {
        ActivityEvent(id: UUID(), title: "Build succeeded", detail: "ExampleApp · iPhone 16 Pro", date: Date(timeIntervalSinceNow: -120), outcome: outcome)
    }
}
