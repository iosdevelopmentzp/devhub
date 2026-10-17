import Foundation
import Testing
@testable import DevHubDomain
import DevHubTestSupport

@Suite struct UpstreamResolverTests {

    @Test func qaAndDevResolveToTheBFFHosts() throws {
        #expect(try UpstreamResolver.upstream(environment: "qa", config: .example).absoluteString == "https://api-qa.example.com")
        #expect(try UpstreamResolver.upstream(environment: " DEV ", config: .example).absoluteString == "https://api-dev.example.com")
    }

    @Test func missingEnvironmentFallsBackToTheDefault() throws {
        #expect(try UpstreamResolver.upstream(environment: nil, config: .example).host == "api-qa.example.com")
    }

    @Test func prodIsRefused() {
        #expect(throws: MockServerError.prodNotSupported) {
            try UpstreamResolver.upstream(environment: "prod", config: .example)
        }
    }

    @Test func unknownEnvironmentIsRefusedWithItsName() {
        #expect(throws: MockServerError.noUpstream(environment: "stage")) {
            try UpstreamResolver.upstream(environment: "stage", config: .example)
        }
    }

    @Test func configWithoutTheTableHasNoUpstream() {
        var saved = DeviceIdentityConfig.example
        saved.mockUpstreams = nil

        #expect(throws: MockServerError.noUpstream(environment: "qa")) {
            try UpstreamResolver.upstream(environment: "qa", config: saved)
        }
    }

    @Test func ownTableWinsAndBadURLsAreRefused() throws {
        var config = DeviceIdentityConfig.example
        config.bundleID = "com.example.other"
        config.mockUpstreams = ["qa": "http://localhost:8080/api", "dev": "not a url"]

        #expect(try UpstreamResolver.upstream(environment: "qa", config: config).absoluteString == "http://localhost:8080/api")
        #expect(throws: MockServerError.noUpstream(environment: "dev")) {
            try UpstreamResolver.upstream(environment: "dev", config: config)
        }
    }

    @Test func environmentNameIsFoundByHost() {
        #expect(UpstreamResolver.environmentName(ofHost: "api-dev.example.com", config: .example) == "dev")
        #expect(UpstreamResolver.environmentName(ofHost: "api-qa.example.com", config: .example) == "qa")
        #expect(UpstreamResolver.environmentName(ofHost: "other.example.com", config: .example) == nil)
    }
}
