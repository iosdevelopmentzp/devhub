import DevHubDomain
import Foundation
import Testing
@testable import DevHubPresentation

@Suite struct MediaChoiceTests {
    @Test func everyChoiceIsAGIFOrACompression() {
        for choice in MediaChoice.allCases {
            #expect((choice.gifOptions == nil) != (choice.compression == nil))
        }
    }

    @Test func everyChoiceHasItsOwnTitle() {
        #expect(Set(MediaChoice.allCases.map(\.title)).count == MediaChoice.allCases.count)
    }
}
