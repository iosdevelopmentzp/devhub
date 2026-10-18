import Testing
@testable import DevHubDomain

@Suite struct CustomTabPolicyTests {
    @Test func refreshModes() {
        #expect(CustomTabPolicy.refresh(for: TabSource(script: "s.sh")) == .onOpen)
        #expect(CustomTabPolicy.refresh(for: TabSource(script: "s.sh", refresh: "onOpen")) == .onOpen)
        #expect(CustomTabPolicy.refresh(for: TabSource(script: "s.sh", refresh: "manual")) == .manual)
        #expect(CustomTabPolicy.refresh(for: TabSource(script: "s.sh", refresh: "30")) == .every(seconds: 30))
        #expect(CustomTabPolicy.refresh(for: TabSource(script: "s.sh", refresh: "1")) == .every(seconds: CustomTabPolicy.minimumInterval))
        #expect(CustomTabPolicy.refresh(for: TabSource(script: "s.sh", refresh: "soon")) == .onOpen)
    }

    @Test func theSourceIsTheScriptAction() {
        #expect(CustomTabPolicy.sourceActionID(for: TabSource(script: "scripts/list-devices.sh")) == "script:list-devices")
    }
}
