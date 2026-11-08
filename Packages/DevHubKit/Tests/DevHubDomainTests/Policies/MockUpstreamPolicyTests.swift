import Foundation
import Testing
@testable import DevHubDomain

@Suite struct MockUpstreamPolicyTests {
    private let staging = LaunchProfile(id: "staging", title: "Staging", upstream: " https://api.staging.example.com ")
    private let dev = LaunchProfile(id: "dev", title: "Dev", upstream: "http://localhost:8080/api")

    @Test func profileUpstreamIsTheURL() throws {
        #expect(try MockUpstreamPolicy.upstream(for: staging).url.absoluteString == "https://api.staging.example.com")
        #expect(try MockUpstreamPolicy.upstream(for: dev).url.absoluteString == "http://localhost:8080/api")
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

    @Test func routesSendAPathPrefixToAnotherUpstream() throws {
        let profile = LaunchProfile(
            id: "qa",
            title: "QA",
            upstream: "https://api-qa.example.com",
            routes: [ProfileRoute(path: " /socket.io/ ", upstream: "https://socket-qa.example.com"), ProfileRoute(path: "/socket.io/admin", upstream: "https://admin-qa.example.com")]
        )

        let upstream = try MockUpstreamPolicy.upstream(for: profile)

        #expect(upstream.url(forPath: "/v1/profile").absoluteString == "https://api-qa.example.com")
        #expect(upstream.url(forPath: "/socket.io/").absoluteString == "https://socket-qa.example.com")
        #expect(upstream.url(forPath: "/socket.io/admin/x").absoluteString == "https://admin-qa.example.com")
    }

    @Test func aBadRouteIsRefusedWithItsPath() {
        let noSlash = LaunchProfile(id: "qa", title: "QA", upstream: "https://api-qa.example.com", routes: [ProfileRoute(path: "socket.io", upstream: "https://socket-qa.example.com")])
        let badURL = LaunchProfile(id: "qa", title: "QA", upstream: "https://api-qa.example.com", routes: [ProfileRoute(path: "/ws", upstream: "wss://socket-qa.example.com")])

        #expect(throws: MockServerError.badRoute(profile: "QA", path: "socket.io")) {
            try MockUpstreamPolicy.upstream(for: noSlash)
        }
        #expect(throws: MockServerError.badRoute(profile: "QA", path: "/ws")) {
            try MockUpstreamPolicy.upstream(for: badURL)
        }
    }

    @Test func profileIsFoundByHost() {
        let profiles = [staging, dev]

        #expect(MockUpstreamPolicy.profile(ofHost: "api.staging.example.com", in: profiles)?.id == "staging")
        #expect(MockUpstreamPolicy.profile(ofHost: "localhost", in: profiles)?.id == "dev")
        #expect(MockUpstreamPolicy.profile(ofHost: "other.example.com", in: profiles) == nil)
    }
}
