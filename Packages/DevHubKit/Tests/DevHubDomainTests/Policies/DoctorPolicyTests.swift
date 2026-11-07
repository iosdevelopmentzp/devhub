import Testing
@testable import DevHubDomain

@Suite struct DoctorPolicyTests {
    @Test func theVersionIsTheFirstDottedNumber() {
        #expect(DoctorPolicy.version(from: ["git version 2.50.1 (Apple Git-155)"]) == "2.50.1")
        #expect(DoctorPolicy.version(from: ["", "Xcode 26.4", "Build version 17E192"]) == "26.4")
        #expect(DoctorPolicy.version(from: ["custom build"]) == "custom build")
        #expect(DoctorPolicy.version(from: []) == nil)
    }

    @Test func everyToolHasAnInstallCommand() {
        #expect(DoctorPolicy.tools.map(\.name) == ["git", "xcodebuild", "xcrun", "gh", "glab", "circleci", "copilot", "claude", "python3", "ffmpeg", "jira"])
        #expect(DoctorPolicy.tools.allSatisfy { $0.installCommand.isEmpty == false })
    }

    @Test func onlyCircleCIHasAMinimumVersion() {
        #expect(DoctorPolicy.tools.first { $0.name == "circleci" }?.minimumMajorVersion == 1)
        #expect(DoctorPolicy.tools.filter { $0.minimumMajorVersion != nil }.map(\.name) == ["circleci"])
    }

    @Test func theMajorVersionDecidesWhetherAToolIsTooOld() {
        #expect(DoctorPolicy.isBelow(minimumMajorVersion: 1, version: "0.1.31425"))
        #expect(DoctorPolicy.isBelow(minimumMajorVersion: 1, version: "1.13.0") == false)
        #expect(DoctorPolicy.isBelow(minimumMajorVersion: 2, version: "v1.9") )
        #expect(DoctorPolicy.isBelow(minimumMajorVersion: 1, version: "custom build") == false)
    }
}
