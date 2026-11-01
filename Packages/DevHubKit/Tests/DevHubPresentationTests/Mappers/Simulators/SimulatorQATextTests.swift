import DevHubDomain
import Foundation
import Testing
@testable import DevHubPresentation

@Suite struct SimulatorQATextTests {
    @Test func theScreenshotNameHasTheSimulatorAndAUTCStamp() {
        let name = SimulatorQAText.screenshotName(simulator: "iPhone 17/Pro", date: Date(timeIntervalSince1970: 1_800_000_000))

        #expect(name == "iPhone 17-Pro 2027-01-15 080000.png")
    }

    @Test func theRecordingNameUsesTheSameStampAsAScreenshot() {
        let name = SimulatorQAText.recordingName(simulator: "iPhone 17/Pro", date: Date(timeIntervalSince1970: 1_800_000_000))

        #expect(name == "iPhone 17-Pro 2027-01-15 080000.mov")
    }

    @Test func everyChoiceHasATitle() {
        #expect(Set(SimulatorTextSize.allCases.map(SimulatorQAText.title)).count == SimulatorTextSize.allCases.count)
        #expect(Set(PrivacyService.allCases.map(SimulatorQAText.title)).count == PrivacyService.allCases.count)
        #expect(SimulatorQAText.logTitle(for: .appearance(.dark), simulator: "iPhone 17") == "Dark appearance on iPhone 17")
        #expect(SimulatorQAText.logTitle(for: .privacy(.grant, service: .photos, bundleID: ""), simulator: "iPad") == "Grant Photos for every app on iPad")
    }
}
