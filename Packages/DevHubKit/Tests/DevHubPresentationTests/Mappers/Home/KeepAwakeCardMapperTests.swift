import DevHubUI
import Testing
@testable import DevHubPresentation

@Suite struct KeepAwakeCardMapperTests {
    @Test func inactive() {
        let model = KeepAwakeCardMapper.model(isActive: false)

        #expect(model.isActive == false)
        #expect(model.systemImage == "moon.zzz.fill")
        #expect(model.tint == .gray)
    }

    @Test func active() {
        let model = KeepAwakeCardMapper.model(isActive: true)

        #expect(model.isActive)
        #expect(model.systemImage == "cup.and.saucer.fill")
        #expect(model.tint == .orange)
        #expect(model.subtitle == "On until you turn it off or quit DevHub")
    }
}
