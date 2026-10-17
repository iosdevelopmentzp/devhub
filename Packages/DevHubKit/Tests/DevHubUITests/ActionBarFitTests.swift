import CoreGraphics
import Testing
@testable import DevHubUI

@Suite struct ActionBarFitTests {
    private let priorities = [1, 3, 2]
    private let labeledWidths: [CGFloat] = [60, 80, 70]
    private let iconWidths: [CGFloat] = [20, 20, 20]

    private func labeled(_ available: CGFloat?) -> Set<Int> {
        ActionBarFit.labeled(priorities: priorities, labeledWidths: labeledWidths, iconWidths: iconWidths, spacing: 5, available: available)
    }

    @Test func everythingIsLabeledWithoutAWidthLimit() {
        #expect(labeled(nil) == [0, 1, 2])
    }

    @Test func everythingIsLabeledWhenItFits() {
        #expect(labeled(220) == [0, 1, 2])
    }

    @Test func theLowestPriorityLosesItsTitleFirst() {
        #expect(labeled(219) == [1, 2])
        #expect(labeled(180) == [1, 2])
    }

    @Test func onlyIconsWhenNothingElseFits() {
        #expect(labeled(70) == [])
    }

    @Test func widthAddsSpacingBetweenItems() {
        #expect(ActionBarFit.width(labeled: [1], labeledWidths: labeledWidths, iconWidths: iconWidths, spacing: 5) == 130)
    }
}
