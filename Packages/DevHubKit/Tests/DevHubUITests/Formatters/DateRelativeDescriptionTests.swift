import Foundation
import Testing
@testable import DevHubUI

@Suite struct DateRelativeDescriptionTests {
    @Test func pastAndFutureDatesGiveText() {
        #expect(Date(timeIntervalSinceNow: -3_600).relativeDescription.isEmpty == false)
        #expect(Date(timeIntervalSinceNow: 86_400 * 3).relativeDescription.isEmpty == false)
        #expect(Date.now.relativeDescription.isEmpty == false)
    }
}
