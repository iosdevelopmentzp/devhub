import Foundation
import Testing
import DevHubDomain
import DevHubMocks
@testable import DevHubPresentation

@Suite struct CrashBannerMapperTests {
    @Test func aClosedBannerNamesTheAppTheExceptionAndTheAppFrame() {
        let model = CrashBannerMapper.model(for: MockData.crashReport, isOpen: false)

        #expect(model.id == MockData.crashReport.path)
        #expect(model.title == "ExampleApp crashed")
        #expect(model.detail == "EXC_BREAKPOINT (SIGTRAP) · ProfileViewModel.load() at ProfileViewModel.swift:42")
        #expect(model.timeText.isEmpty == false)
        #expect(model.messages == MockData.crashReport.messages)
        #expect(model.frames.isEmpty)
        #expect(model.toggleTitle == "Show Stack")
        #expect(model.reportPath == MockData.crashReport.path)
    }

    @Test func anOpenBannerListsTheFramesWithThePlace() {
        let model = CrashBannerMapper.model(for: MockData.crashReport, isOpen: true)

        #expect(model.toggleTitle == "Hide Stack")
        #expect(model.frames.map(\.text) == [
            "libswiftCore.dylib · _assertionFailure(_:_:file:line:flags:)",
            "ExampleApp.debug.dylib · ProfileViewModel.load()",
            "ExampleApp.debug.dylib · closure #1 in ProfileView.body.getter",
            "SwiftUI · ViewGraph.updateOutputs()",
        ])
        #expect(model.frames.map(\.place) == [nil, "ProfileViewModel.swift:42", "ProfileView.swift:18", nil])
        #expect(model.frames.map(\.isApp) == [false, true, true, false])
        #expect(model.hiddenFrameCount == 0)
    }

    @Test func aLongStackIsCut() {
        var report = MockData.crashReport
        report.frames = Array(repeating: CrashReport.Frame(image: "A", symbol: "f", file: nil, line: nil, isApp: false), count: 20)

        let model = CrashBannerMapper.model(for: report, isOpen: true)

        #expect(model.frames.count == CrashBannerMapper.frameLimit)
        #expect(model.hiddenFrameCount == 5)
    }

    @Test func aReportWithoutDetailsSaysSo() {
        var report = MockData.crashReport
        report.exceptionType = nil
        report.signal = nil
        report.frames = []

        #expect(CrashBannerMapper.detail(for: report) == "No exception in the report")
    }
}
