import Foundation
import Testing
@testable import DevHubDomain

@Suite struct CIJobDetailsTests {
    private let start = Date(timeIntervalSince1970: 1_800_000_000)

    @Test func theDurationUsesTheStopTimeOrNow() {
        let finished = CIJobDetails(id: "j", number: 1, startedAt: start, stoppedAt: start.addingTimeInterval(130), approvalRequestID: nil)
        let running = CIJobDetails(id: "j", number: 1, startedAt: start, stoppedAt: nil, approvalRequestID: nil)
        let waiting = CIJobDetails(id: "j", number: nil, startedAt: nil, stoppedAt: nil, approvalRequestID: nil)

        #expect(finished.duration(now: start.addingTimeInterval(1000)) == 130)
        #expect(running.duration(now: start.addingTimeInterval(45)) == 45)
        #expect(running.duration(now: start.addingTimeInterval(-10)) == 0)
        #expect(waiting.duration(now: start) == nil)
    }
}
