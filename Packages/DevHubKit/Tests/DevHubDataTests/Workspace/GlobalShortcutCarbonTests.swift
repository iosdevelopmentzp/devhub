import DevHubDomain
import Testing
@testable import DevHubData

@Suite struct GlobalShortcutCarbonTests {
    @Test func offHasNoKey() {
        #expect(GlobalShortcut.off.carbonKey == nil)
    }

    @Test(arguments: [
        (GlobalShortcut.optionCommandD, UInt32(0x02), UInt32(2048 | 256)),
        (.controlOptionSpace, 0x31, 4096 | 2048),
        (.controlOptionD, 0x02, 4096 | 2048),
    ])
    func mapsKeyAndModifiers(shortcut: GlobalShortcut, code: UInt32, modifiers: UInt32) throws {
        let key = try #require(shortcut.carbonKey)

        #expect(key.code == code)
        #expect(key.modifiers == modifiers)
    }
}
