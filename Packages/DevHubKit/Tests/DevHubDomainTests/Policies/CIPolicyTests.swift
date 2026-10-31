import Testing
@testable import DevHubDomain

@Suite struct CIPolicyTests {
    @Test func theConfigKindWinsOverTheDetection() {
        #expect(CIPolicy.provider(config: CIConfig(kind: "circleci"), hasCircleCIConfig: false) == .circleci)
        #expect(CIPolicy.provider(config: CIConfig(kind: "CircleCI"), hasCircleCIConfig: false) == .circleci)
        #expect(CIPolicy.provider(config: CIConfig(kind: "none"), hasCircleCIConfig: true) == nil)
        #expect(CIPolicy.provider(config: CIConfig(kind: "jenkins"), hasCircleCIConfig: true) == nil)
    }

    @Test func withoutAKindTheConfigFileDecides() {
        #expect(CIPolicy.provider(config: nil, hasCircleCIConfig: true) == .circleci)
        #expect(CIPolicy.provider(config: CIConfig(project: "gh/example/app"), hasCircleCIConfig: true) == .circleci)
        #expect(CIPolicy.provider(config: nil, hasCircleCIConfig: false) == nil)
    }

    @Test func theConfigFileLivesInTheCheckout() {
        #expect(CIPolicy.circleCIConfigPath(checkoutPath: "/repo") == "/repo/.circleci/config.yml")
    }

    @Test func onlyTheOneLineIsSupported() {
        #expect(CIPolicy.isSupported(version: "1.13.0"))
        #expect(CIPolicy.isSupported(version: "2.0"))
        #expect(CIPolicy.isSupported(version: "v1.2"))
        #expect(CIPolicy.isSupported(version: "0.1.31425") == false)
        #expect(CIPolicy.isSupported(version: "") == false)
    }

    @Test func theInstallCommandFollowsTheToolState() {
        #expect(CIPolicy.installCommand(for: .missing) == "brew install circleci && circleci auth login")
        #expect(CIPolicy.installCommand(for: CIToolState(isInstalled: true, version: "0.1.3", isLoggedIn: false)) == "brew upgrade circleci")
        #expect(CIPolicy.installCommand(for: CIToolState(isInstalled: true, version: "1.13.0", isLoggedIn: false)) == "circleci auth login")
        #expect(CIPolicy.installCommand(for: CIToolState(isInstalled: true, version: nil, isLoggedIn: false)) == "circleci auth login")
        #expect(CIPolicy.installCommand(for: CIToolState(isInstalled: true, version: "1.13.0", isLoggedIn: true)) == nil)
    }
}
