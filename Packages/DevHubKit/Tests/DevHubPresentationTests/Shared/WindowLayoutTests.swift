import CoreGraphics
import DevHubMocks
import Testing
@testable import DevHubPresentation

@Suite struct WindowLayoutTests {
    let store = InMemoryKeyValueStore()

    @Test func sizesAreFixed() {
        #expect(WindowLayout.minimumSize == CGSize(width: 640, height: 560))
        #expect(WindowLayout.defaultSize == CGSize(width: 720, height: 820))
    }

    @Test func startsWithDefaultSizeAndNoPosition() {
        let layout = WindowLayout(store: store)

        #expect(layout.size == WindowLayout.defaultSize)
        #expect(layout.panelTopLeft == nil)
    }

    @Test func readsSavedSizeRoundedDown() {
        store.set([700.7, 600.2], forKey: "window.size")

        #expect(WindowLayout(store: store).size == CGSize(width: 700, height: 600))
    }

    @Test func savedSizeBelowMinimumIsClamped() {
        store.set([100, 100], forKey: "window.size")

        #expect(WindowLayout(store: store).size == WindowLayout.minimumSize)
    }

    @Test func malformedSavedSizeFallsBackToDefault() {
        store.set([700], forKey: "window.size")

        #expect(WindowLayout(store: store).size == WindowLayout.defaultSize)
    }

    @Test func clampedRespectsMinimumSize() {
        #expect(WindowLayout.clamped(CGSize(width: 10, height: 10)) == WindowLayout.minimumSize)
        #expect(WindowLayout.clamped(CGSize(width: 10, height: 700)) == CGSize(width: 640, height: 700))
    }

    @Test func sizeChangeIsSaved() {
        let layout = WindowLayout(store: store)

        layout.size = CGSize(width: 800, height: 700)

        #expect(store.doubles(forKey: "window.size") == [800, 700])
    }

    @Test func resizeWithoutWindowClampsTheProposal() {
        let layout = WindowLayout(store: store)

        layout.resize(to: CGSize(width: 100, height: 100), in: nil)

        #expect(layout.size == WindowLayout.minimumSize)
    }

    @Test func resetRestoresDefaultSize() {
        let layout = WindowLayout(store: store)
        layout.size = CGSize(width: 800, height: 700)

        layout.reset()

        #expect(layout.size == WindowLayout.defaultSize)
    }

    @Test func panelTopLeftIsSavedAndRemoved() {
        let layout = WindowLayout(store: store)

        layout.panelTopLeft = CGPoint(x: 120, y: 900)
        #expect(store.doubles(forKey: "window.panelTopLeft") == [120, 900])

        layout.panelTopLeft = nil
        #expect(store.doubles(forKey: "window.panelTopLeft") == nil)
    }

    @Test func readsSavedPanelTopLeft() {
        store.set([120, 900], forKey: "window.panelTopLeft")

        #expect(WindowLayout(store: store).panelTopLeft == CGPoint(x: 120, y: 900))
    }
}
