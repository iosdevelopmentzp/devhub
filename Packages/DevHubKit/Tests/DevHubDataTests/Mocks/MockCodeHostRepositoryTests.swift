import DevHubDomain
import Foundation
import Testing
import DevHubTestSupport
@testable import DevHubMocks

@Suite struct MockCodeHostRepositoryTests {
    @Test func answersAnOpenPullRequestWithAPipeline() async throws {
        let status = try await MockCodeHostRepository().status(branch: "feature", repository: .gitLabSample)

        #expect(status.pullRequest?.iid == 1842)
        #expect(status.pullRequest?.state == .opened)
        #expect(status.pullRequest?.detailedStatus == .notApproved)
        #expect(status.pipeline?.status == .success)
    }
}
