import DevHubTestSupport
import Testing
@testable import DevHubPresentation

@Suite struct ToasterTests {
    private let written = Written()

    @Test func copyWritesTheValueAndShowsTheLabel() {
        let toaster = makeToaster()

        toaster.copy("a1b2c3d4e5f6", label: "hash")

        #expect(written.values == ["a1b2c3d4e5f6"])
        #expect(toaster.text == "Copied: hash")
    }

    @Test func copyWithoutLabelShowsTheValue() {
        let toaster = makeToaster()

        toaster.copy("feature/login")

        #expect(written.values == ["feature/login"])
        #expect(toaster.text == "Copied: feature/login")
    }

    @Test func labelOfFortyEightCharactersIsKept() {
        let toaster = makeToaster()
        let label = String(repeating: "a", count: 48)

        toaster.copy("value", label: label)

        #expect(toaster.text == "Copied: \(label)")
    }

    @Test func longerLabelIsCutToFortyFiveCharactersAndEllipsis() {
        let toaster = makeToaster()
        let label = String(repeating: "a", count: 45) + "bcdef"

        toaster.copy("value", label: label)

        #expect(toaster.text == "Copied: \(String(repeating: "a", count: 45))…")
    }

    @Test func showSetsTheText() {
        let toaster = makeToaster()

        toaster.show("Saved")

        #expect(toaster.text == "Saved")
        #expect(written.values.isEmpty)
    }

    @Test func textHidesAfterADelay() async throws {
        let toaster = makeToaster()

        toaster.show("Saved")

        try await waitUntil(timeout: .seconds(4)) { toaster.text == nil }
    }

    private func makeToaster() -> Toaster {
        let written = written
        return Toaster { written.values.append($0) }
    }
}

private final class Written {
    var values: [String] = []
}
