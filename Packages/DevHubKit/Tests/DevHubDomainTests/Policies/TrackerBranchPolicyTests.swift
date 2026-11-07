import Foundation
import Testing
@testable import DevHubDomain

@Suite struct TrackerBranchPolicyTests {
    @Test func theSlugIsLowercaseASCIIWithDashes() {
        #expect(TrackerBranchPolicy.slug("Login button stays disabled!") == "login-button-stays-disabled")
        #expect(TrackerBranchPolicy.slug("  [Chats] VIP user sees \"Assistant\"  ") == "chats-vip-user-sees-assistant")
        #expect(TrackerBranchPolicy.slug("Крэш при запуске") == "")
        #expect(TrackerBranchPolicy.slug("Fix v2.1 crash") == "fix-v2-1-crash")
    }

    @Test func aLongSlugIsCutAtADash() {
        let slug = TrackerBranchPolicy.slug("the quick brown fox jumps over the lazy dog again and again")

        #expect(slug == "the-quick-brown-fox-jumps-over-the-lazy")
        #expect(slug.count <= TrackerBranchPolicy.maximumSlugLength)
    }

    @Test func theBranchNameFollowsTheFormat() {
        let issue = issue(summary: "Login button stays disabled")

        #expect(TrackerBranchPolicy.branchName(for: issue, format: "feature/{key}-{slug}") == "feature/ABC-123-login-button-stays-disabled")
        #expect(TrackerBranchPolicy.branchName(for: issue, format: "{key}") == "ABC-123")
    }

    @Test func anEmptySlugLeavesNoTrailingDash() {
        let issue = issue(summary: "Крэш")

        #expect(TrackerBranchPolicy.branchName(for: issue, format: "feature/{key}-{slug}") == "feature/ABC-123")
        #expect(TrackerBranchPolicy.branchName(for: issue, format: "{slug}/{key}") == "/ABC-123")
    }

    private func issue(summary: String) -> TrackerIssue {
        TrackerIssue(key: "ABC-123", summary: summary, status: "To Do", statusCategory: .toDo, type: "Bug", priority: nil, assignee: nil, url: nil, updatedAt: nil)
    }
}
