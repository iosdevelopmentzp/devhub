import Foundation
import Testing
@testable import DevHubData

@Suite struct CopilotEventScannerTests {
    @Test func findsTheFirstAndLastUserMessage() {
        let events = """
        {"type":"session.start","data":{"sessionId":"1a2b"}}
        {"type":"user.message","data":{"content":"Add the\\nlogin screen"}}
        {"type":"assistant.message","data":{"content":"Done"}}
        {"type":"user.message","data":{"content":"   "}}
        {"type":"user.message","data":{"content":"Run the tests"}}
        {"type":"assistant.message","data":{"content":"All green"}}
        """

        let prompts = CopilotEventScanner.scan(Data(events.utf8))

        #expect(prompts == CopilotEventScanner.Prompts(first: "Add the login screen", last: "Run the tests"))
    }

    @Test func noUserMessageMeansNoPrompts() {
        #expect(CopilotEventScanner.scan(Data(#"{"type":"session.start","data":{}}"#.utf8)) == CopilotEventScanner.Prompts())
        #expect(CopilotEventScanner.scan(Data()) == CopilotEventScanner.Prompts())
    }
}
