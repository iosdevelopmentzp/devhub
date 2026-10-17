import DevHubDomain
import Foundation
import Testing
@testable import DevHubMocks

@Suite struct MockMergeRequestRepositoryTests {
    @Test func answersAnOpenMergeRequestWithAPipeline() async throws {
        let status = try await MockMergeRequestRepository().status(branch: "feature", repository: URL(fileURLWithPath: "/"))

        #expect(status.mergeRequest?.iid == 1842)
        #expect(status.mergeRequest?.state == .opened)
        #expect(status.mergeRequest?.detailedStatus == .notApproved)
        #expect(status.pipeline?.status == .success)
    }
}
