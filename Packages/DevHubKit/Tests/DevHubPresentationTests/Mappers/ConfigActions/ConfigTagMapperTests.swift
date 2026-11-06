import DevHubDomain
import DevHubUI
import Testing
@testable import DevHubPresentation

@Suite struct ConfigTagMapperTests {

    @Test func everyFieldIsCopiedAndTheTintDefaultsToGray() {
        #expect(ConfigTagMapper.model(ScriptViewTag(text: "beta", tint: .purple, icon: "flask", hint: "Beta build")) == TagModel("beta", tint: .purple, systemImage: "flask", hint: "Beta build"))
        #expect(ConfigTagMapper.model(ScriptViewTag(text: "plain")) == TagModel("plain", tint: .gray))
    }
}
