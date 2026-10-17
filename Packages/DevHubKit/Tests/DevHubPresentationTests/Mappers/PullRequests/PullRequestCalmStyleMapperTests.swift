import DevHubDomain
import DevHubUI
import Foundation
import Testing
@testable import DevHubPresentation

@Suite struct PullRequestCalmStyleMapperTests {
    @Test func tagsTurnGreyExceptProblemsAndYourReview() {
        var model = PullRequestRowModel.preview
        model.tags = [
            TagModel("conflicts", tint: .red, systemImage: "exclamationmark.triangle.fill"),
            TagModel("needs your review", tint: .indigo, systemImage: "eye"),
            TagModel("behind dev", tint: .orange, systemImage: "arrow.down"),
            TagModel("approved by lee", tint: .green, systemImage: "checkmark.seal.fill"),
        ]

        let calm = PullRequestCalmStyleMapper.calm(model)

        #expect(calm.usesPlainTags)
        #expect(calm.tags.map(\.tint) == [.red, .indigo, .secondary, .secondary])
        #expect(calm.tags.map(\.text) == model.tags.map(\.text))
        #expect(calm.tags.map(\.systemImage) == model.tags.map(\.systemImage))
    }

    @Test func theTicketChipGoesWhenTheTitleHasTheKey() {
        var model = PullRequestRowModel.preview
        model.title = "ABC-2324: Paid call payment"

        #expect(PullRequestCalmStyleMapper.calm(model).ticket == nil)

        model.title = "Paid call payment"
        #expect(PullRequestCalmStyleMapper.calm(model).ticket == model.ticket)
    }

    @Test func otherFactsStayTheSame() {
        let model = PullRequestRowModel.preview

        let calm = PullRequestCalmStyleMapper.calm(model)

        #expect(calm.pipelineTag == model.pipelineTag)
        #expect(calm.statsText == model.statsText)
        #expect(calm.primaryActions == model.primaryActions)
        #expect(calm.labelTags.map(\.text) == model.labelTags.map(\.text))
    }
}
