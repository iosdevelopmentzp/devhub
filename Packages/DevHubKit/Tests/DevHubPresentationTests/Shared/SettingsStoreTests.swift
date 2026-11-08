import DevHubDomain
import DevHubMocks
import Testing
@testable import DevHubPresentation

@Suite struct SettingsStoreTests {
    let store = InMemoryKeyValueStore()

    @Test func startsWithGivenValues() {
        let values = AppSettings(editor: "Cursor")

        #expect(SettingsStore(values: values, store: store).values == values)
    }

    @Test func changedValuesAreSaved() {
        let settings = SettingsStore(values: AppSettings(), store: store)

        settings.values.editor = "Cursor"
        settings.values.terminal = "iTerm"

        #expect(store.decode(AppSettings.self, forKey: "app.settings") == AppSettings(editor: "Cursor", terminal: "iTerm"))
    }

    @Test func diffFontSizeChangesInStepsAndResetsToTheStandardSize() {
        let settings = SettingsStore(values: AppSettings(), store: store)

        settings.changeDiffFontSize(by: 2)
        #expect(settings.values.diffFontSize == DiffFontSizePolicy.standard + 2)
        #expect(store.decode(AppSettings.self, forKey: "app.settings")?.diffFontSize == DiffFontSizePolicy.standard + 2)

        settings.changeDiffFontSize(by: 100)
        #expect(settings.values.diffFontSize == DiffFontSizePolicy.range.upperBound)

        settings.resetDiffFontSize()
        #expect(settings.values.diffFontSize == DiffFontSizePolicy.standard)
    }

    @Test func unchangedValuesAreNotSaved() {
        let settings = SettingsStore(values: AppSettings(), store: store)

        settings.values = AppSettings()

        #expect(store.data(forKey: "app.settings") == nil)
    }

    @Test func shortcutChangeCallsTheHandler() {
        let settings = SettingsStore(values: AppSettings(), store: store)
        let received = Received()
        settings.onShortcutChange = { received.shortcuts.append($0) }

        settings.values.globalShortcut = .controlOptionSpace

        #expect(received.shortcuts == [.controlOptionSpace])
    }

    @Test func otherChangesDoNotCallTheShortcutHandler() {
        let settings = SettingsStore(values: AppSettings(), store: store)
        let received = Received()
        settings.onShortcutChange = { received.shortcuts.append($0) }

        settings.values.editor = "Cursor"
        settings.values.showUsageStrip = false
        settings.values.globalShortcut = .optionCommandD

        #expect(received.shortcuts.isEmpty)
    }
}

private final class Received {
    var shortcuts: [GlobalShortcut] = []
}
