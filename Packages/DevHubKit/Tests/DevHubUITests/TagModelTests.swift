import Testing
@testable import DevHubUI

@Suite struct TagModelTests {
    @Test func defaultsAreSecondaryWithoutImageOrHint() {
        let tag = TagModel("clean")

        #expect(tag.text == "clean")
        #expect(tag.tint == .secondary)
        #expect(tag.systemImage == nil)
        #expect(tag.hint == nil)
    }

    @Test func equalWhenEveryFieldMatches() {
        let tag = TagModel("merged", tint: .purple, systemImage: "arrow.triangle.merge", hint: "Safe to delete")

        #expect(tag == TagModel("merged", tint: .purple, systemImage: "arrow.triangle.merge", hint: "Safe to delete"))
        #expect(tag != TagModel("merged", tint: .blue, systemImage: "arrow.triangle.merge", hint: "Safe to delete"))
        #expect(tag != TagModel("merged", tint: .purple, systemImage: nil, hint: "Safe to delete"))
        #expect(tag != TagModel("merged", tint: .purple, systemImage: "arrow.triangle.merge", hint: nil))
        #expect(tag != TagModel("Merged", tint: .purple, systemImage: "arrow.triangle.merge", hint: "Safe to delete"))
    }

    @Test func hashingFollowsEquality() {
        let tags: Set<TagModel> = [
            TagModel("clean", tint: .green),
            TagModel("clean", tint: .green),
            TagModel("clean", tint: .orange)
        ]

        #expect(tags.count == 2)
    }

    @Test func iconFormHasNoText() {
        let tag = TagModel.icon("checkmark.circle.fill", tint: .green, hint: "Pipeline passed")

        #expect(tag == TagModel("", tint: .green, systemImage: "checkmark.circle.fill", hint: "Pipeline passed"))
    }
}
