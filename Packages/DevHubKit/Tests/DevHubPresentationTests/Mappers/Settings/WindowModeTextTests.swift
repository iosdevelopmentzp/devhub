import DevHubDomain
import Testing
@testable import DevHubPresentation

@Suite struct WindowModeTextTests {
    @Test func everyModeHasItsOwnTitleAndHints() {
        #expect(WindowModeText.title(for: .panel) == "Menu bar panel")
        #expect(WindowModeText.title(for: .window) == "Normal window")
        #expect(Set(WindowMode.allCases.map(WindowModeText.hint)).count == WindowMode.allCases.count)
        #expect(WindowModeText.shortcutHint(for: .window).contains("current desktop"))
    }
}
