import DevHubDomain
import Foundation
import Testing
@testable import DevHubPresentation

@Suite struct NotificationFilterTests {
    @Test func allKindAndOtherMatchTheRightEvents() {
        let build = ActivityEvent(id: UUID(), title: "", detail: "", date: .now, outcome: .info, kind: .build)
        let plain = ActivityEvent(id: UUID(), title: "", detail: "", date: .now, outcome: .info)

        #expect(NotificationFilter.all.includes(build))
        #expect(NotificationFilter.all.includes(plain))
        #expect(NotificationFilter.kind(.build).includes(build))
        #expect(NotificationFilter.kind(.build).includes(plain) == false)
        #expect(NotificationFilter.kind(.tests).includes(build) == false)
        #expect(NotificationFilter.other.includes(plain))
        #expect(NotificationFilter.other.includes(build) == false)
    }
}
