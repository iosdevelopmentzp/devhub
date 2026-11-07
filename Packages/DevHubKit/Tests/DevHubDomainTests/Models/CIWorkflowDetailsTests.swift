import Foundation
import Testing
@testable import DevHubDomain

@Suite struct CIWorkflowDetailsTests {
    @Test func aJobIsFoundByItsID() {
        let details = CIWorkflowDetails(id: "w1", pipelineNumber: 42, projectSlug: "gh/example/app", createdAt: nil, stoppedAt: nil, jobs: [
            CIJobDetails(id: "j1", number: 101, startedAt: nil, stoppedAt: nil, approvalRequestID: nil),
            CIJobDetails(id: "j2", number: 102, startedAt: nil, stoppedAt: nil, approvalRequestID: "a1"),
        ])

        #expect(details.job("j2")?.number == 102)
        #expect(details.job("j3") == nil)
    }
}
