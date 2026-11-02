import AppKit
import Testing
@testable import DevHubUI

@Suite struct FileDropViewTests {
    @Test func theViewTakesFileDropsAndFillsItsButton() {
        let view = FileDropView(accepts: { _ in true }, onTarget: { _ in }, onDrop: { _ in }, onClick: {})

        #expect(view.registeredDraggedTypes.contains(.fileURL))
        #expect(view.autoresizingMask == [.width, .height])
        #expect(view.acceptsFirstMouse(for: nil))
    }

    @Test func leftAndRightClicksReachTheButtonAction() throws {
        var clicks = 0
        let view = FileDropView(accepts: { _ in true }, onTarget: { _ in }, onDrop: { _ in }, onClick: { clicks += 1 })
        let left = try #require(NSEvent.mouseEvent(with: .leftMouseDown, location: .zero, modifierFlags: [], timestamp: 0, windowNumber: 0, context: nil, eventNumber: 0, clickCount: 1, pressure: 1))
        let right = try #require(NSEvent.mouseEvent(with: .rightMouseDown, location: .zero, modifierFlags: [], timestamp: 0, windowNumber: 0, context: nil, eventNumber: 0, clickCount: 1, pressure: 1))

        view.mouseDown(with: left)
        view.rightMouseDown(with: right)

        #expect(clicks == 2)
    }
}
