import Testing
@testable import DevHubDomain

@Suite struct VideoEngineStatusTests {
    @Test func onlyAReadyEngineIsReady() {
        #expect(VideoEngineStatus.ready(version: "9.0.2", path: "/opt/homebrew/bin/ffmpeg").isReady)
        #expect(VideoEngineStatus.incomplete(version: "9.0.2", path: "/opt/homebrew/bin/ffmpeg", missing: "libx264").isReady == false)
        #expect(VideoEngineStatus.missing(homebrewPath: "/opt/homebrew/bin/brew").isReady == false)
    }
}
