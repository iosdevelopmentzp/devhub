import DevHubDomain
import DevHubUI
import Foundation
import Testing
@testable import DevHubPresentation

@Suite struct LaunchProfileMapperTests {
    private let staging = LaunchProfile(id: "staging", title: "Staging", env: ["API_ENV": "staging"], args: ["-Debug"], defaults: [ProfileDefault(suite: "group.com.example.app", key: "environment", value: "staging")])
    private let production = LaunchProfile(id: "production", title: "Production", cleanInstall: true, production: true)

    @Test func noProfileMeansNoPicker() {
        #expect(LaunchProfileMapper.model(profiles: [], selected: nil) == nil)
    }

    @Test func theSummaryListsWhatTheProfileSets() throws {
        let model = try #require(LaunchProfileMapper.model(profiles: [staging, production], selected: staging))

        #expect(model.options.map(\.title) == ["Staging", "Production"])
        #expect(model.selectedID == "staging")
        #expect(model.usesSegments)
        #expect(model.summary == "API_ENV=staging · 1 argument · 1 default")
        #expect(model.details == "env API_ENV=staging\narg -Debug\ndefault group.com.example.app · environment = staging")
    }

    @Test func aCleanInstallProfileSaysSo() throws {
        let model = try #require(LaunchProfileMapper.model(profiles: [staging, production], selected: production))

        #expect(model.summary == "clean install")
    }

    @Test func manyProfilesUseAMenu() throws {
        let profiles = (1...5).map { LaunchProfile(id: "p\($0)", title: "P\($0)") }

        #expect(try #require(LaunchProfileMapper.model(profiles: profiles, selected: profiles[0])).usesSegments == false)
    }

    @Test func aProductionProfileIsMarked() throws {
        let onStaging = try #require(LaunchProfileMapper.model(profiles: [staging, production], selected: staging))
        let onProduction = try #require(LaunchProfileMapper.model(profiles: [staging, production], selected: production))

        #expect(onStaging.options.map(\.isProduction) == [false, true])
        #expect(onStaging.productionTag == nil)
        #expect(onProduction.productionTag?.tint == .red)
    }
}
