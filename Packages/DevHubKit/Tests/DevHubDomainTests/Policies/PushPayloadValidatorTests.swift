import Testing
@testable import DevHubDomain

@Suite struct PushPayloadValidatorTests {
    @Test func validPayloadHasNoError() {
        #expect(PushPayloadValidator.error(in: #"{"aps":{"alert":"Hi"}}"#) == nil)
    }

    @Test func brokenJSONIsInvalid() {
        #expect(PushPayloadValidator.error(in: #"{"aps":"#) == "Invalid JSON")
    }

    @Test func topLevelStringIsInvalidJSON() {
        #expect(PushPayloadValidator.error(in: #""text""#) == "Invalid JSON")
    }

    @Test func arrayIsNotAnObject() {
        #expect(PushPayloadValidator.error(in: "[1, 2]") == "The payload must be a JSON object")
    }

    @Test func objectWithoutApsNeedsTheKey() {
        #expect(PushPayloadValidator.error(in: #"{"alert":"Hi"}"#) == "The payload needs an \"aps\" key")
    }
}
