import Foundation
import Testing
@testable import DevHubDomain

@Suite struct MockUpstreamPolicyTests {
    private let staging = LaunchProfile(id: "staging", title: "Staging", upstream: " https://api.staging.example.com ")
    private let dev = LaunchProfile(id: "dev", title: "Dev", upstream: "http://localhost:8080/api")

    @Test func profileUpstreamIsTheURL() throws {
        #expect(try MockUpstreamPolicy.upstream(for: staging).absoluteString == "https://api.staging.example.com")
        #expect(try MockUpstreamPolicy.upstream(for: dev).absoluteString == "http://localhost:8080/api")
    }

    @Test func noProfileIsRefused() {
        #expect(throws: MockServerError.noProfile) {
            try MockUpstreamPolicy.upstream(for: nil)
        }
    }

    @Test func productionIsRefused() {
        let production = LaunchProfile(id: "prod", title: "Production", upstream: "https://api.example.com", production: true)

        #expect(throws: MockServerError.productionRefused(profile: "Production")) {
            try MockUpstreamPolicy.upstream(for: production)
        }
    }

    @Test func missingOrBadUpstreamIsRefusedWithTheProfileName() {
        #expect(throws: MockServerError.noUpstream(profile: "Plain")) {
            try MockUpstreamPolicy.upstream(for: LaunchProfile(id: "plain", title: "Plain"))
        }
        #expect(throws: MockServerError.noUpstream(profile: "Bad")) {
            try MockUpstreamPolicy.upstream(for: LaunchProfile(id: "bad", title: "Bad", upstream: "not a url"))
        }
        #expect(throws: MockServerError.noUpstream(profile: "FTP")) {
            try MockUpstreamPolicy.upstream(for: LaunchProfile(id: "ftp", title: "FTP", upstream: "ftp://files.example.com"))
        }
    }

    @Test func profileIsFoundByHost() {
        let profiles = [staging, dev]

        #expect(MockUpstreamPolicy.profile(ofHost: "api.staging.example.com", in: profiles)?.id == "staging")
        #expect(MockUpstreamPolicy.profile(ofHost: "localhost", in: profiles)?.id == "dev")
        #expect(MockUpstreamPolicy.profile(ofHost: "other.example.com", in: profiles) == nil)
    }
}
