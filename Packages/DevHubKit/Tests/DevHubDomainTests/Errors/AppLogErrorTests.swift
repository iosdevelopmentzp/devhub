import Testing
@testable import DevHubDomain

@Suite struct AppLogErrorTests {
    @Test func streamStoppedNamesTheExitCode() {
        let description = AppLogError.streamStopped(9).errorDescription

        #expect(description?.contains("9") == true)
    }
}
