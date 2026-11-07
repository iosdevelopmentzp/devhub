import Foundation
import Testing
@testable import DevHubUI

@Suite struct ISOTimestampTests {
    @Test func textIsTheInternetDateTimeInUTC() {
        #expect(ISOTimestamp.text(Date(timeIntervalSince1970: 1_800_000_000)) == "2027-01-15T08:00:00Z")
    }

    @Test func fileNameHasNoColonsOrSlashes() {
        let name = ISOTimestamp.fileName(Date(timeIntervalSince1970: 1_800_000_000))

        #expect(name.count == 16)
        #expect(name.contains(":") == false)
        #expect(name.contains("/") == false)
    }
}
