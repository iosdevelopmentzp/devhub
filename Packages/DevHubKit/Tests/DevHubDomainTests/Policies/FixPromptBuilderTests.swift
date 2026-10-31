import Testing
@testable import DevHubDomain

@Suite struct FixPromptBuilderTests {
    private let failure = TestFailure(test: "LoginTests.testLogin", file: "LoginTests.swift", path: "/repo/Tests/LoginTests.swift", line: 42, message: "XCTAssertEqual failed: (\"a\") is not equal to (\"b\")\nsecond line")
    private let error = BuildIssue(severity: .error, path: "/repo/Sources/Login.swift", line: 7, column: 3, message: "cannot find 'token' in scope")
    private let warning = BuildIssue(severity: .warning, path: nil, line: nil, column: nil, message: "unused variable")

    @Test func theTestsPromptListsFailuresIssuesAndTheSteps() {
        let prompt = FixPromptBuilder.tests(scheme: "ExampleApp", checkoutName: "feature/ABC-123", passed: 11, failed: 1, skipped: 2, failures: [failure], issues: [error, warning])

        #expect(prompt.hasPrefix("# Failed tests of ExampleApp in feature/ABC-123\n\nThe run gave 11 passed, 1 failed and 2 skipped tests.\n"))
        #expect(prompt.contains("## Failure 1: `LoginTests.testLogin` (`LoginTests.swift:42`)\n\n> XCTAssertEqual failed: (\"a\") is not equal to (\"b\")\n> second line\n"))
        #expect(prompt.contains("## Compiler errors\n\n- `/repo/Sources/Login.swift:7`: cannot find 'token' in scope\n"))
        #expect(prompt.contains("## Warnings (fix only when they touch the errors above)\n\n- unused variable\n"))
        #expect(prompt.contains("## What to do\n\n1. Make every failed test above pass"))
        #expect(prompt.hasSuffix("\n"))
    }

    @Test func theBuildPromptCountsTheErrorsAndSkipsEmptySections() {
        let prompt = FixPromptBuilder.build(scheme: "ExampleApp", checkoutName: "~/Projects/example-app", issues: [error])

        #expect(prompt.hasPrefix("# Build errors of ExampleApp in ~/Projects/example-app\n\nThe build of ExampleApp failed with 1 errors.\n"))
        #expect(prompt.contains("## Compiler errors\n\n- `/repo/Sources/Login.swift:7`: cannot find 'token' in scope\n"))
        #expect(prompt.contains("## Warnings") == false)
        #expect(prompt.contains("1. Make the build pass in this checkout."))
    }

    @Test func aFailureWithoutTestOrFileStillGetsABlock() {
        let plain = TestFailure(test: nil, file: nil, path: nil, line: nil, message: "crashed")

        let prompt = FixPromptBuilder.tests(scheme: "App", checkoutName: "main", passed: 0, failed: 1, skipped: 0, failures: [plain], issues: [])

        #expect(prompt.contains("## Failure 1\n\n> crashed\n"))
        #expect(prompt.contains("## Compiler errors") == false)
    }

    @Test func fileNamesAreSlugs() {
        #expect(FixPromptBuilder.fileName(forTestsOf: "feature/ABC-123 login") == "fix-tests-feature-abc-123-login")
        #expect(FixPromptBuilder.fileName(forBuildOf: "Example App") == "fix-build-example-app")
        #expect(FixPromptBuilder.fileName(forTestsOf: "///") == "fix-tests-checkout")
    }
}
