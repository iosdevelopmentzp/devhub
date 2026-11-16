import DevHubDomain
import DevHubUI
import Testing
@testable import DevHubPresentation

@Suite struct BuildIssuesMapperTests {
    private let warning = BuildIssue(severity: .warning, path: "/p/Old.swift", line: 7, column: nil, message: "deprecated")
    private let error = BuildIssue(severity: .error, path: "/p/LoginView.swift", line: 42, column: 9, message: "cannot find 'viewModel' in scope")
    private let loose = BuildIssue(severity: .error, path: nil, line: nil, column: nil, message: "Unable to find a destination")

    @Test func errorsComeFirstWithTheFileAndLine() {
        let rows = BuildIssuesMapper.rows(for: [warning, error, loose])

        #expect(rows.map(\.location) == ["LoginView.swift:42", nil, "Old.swift:7"])
        #expect(rows.map(\.tint) == [.red, .red, .orange])
        #expect(rows[0].hint == "Open /p/LoginView.swift at line 42")
        #expect(rows[1].path == nil)
    }

    @Test func theTitleCountsErrorsAndWarnings() {
        #expect(BuildIssuesMapper.title(for: [warning, error, loose]) == "2 errors · 1 warning")
        #expect(BuildIssuesMapper.title(for: [warning]) == "1 warning")
    }

    @Test func everyIssueCopiesAsACompilerLine() {
        #expect(BuildIssuesMapper.copyText(for: [warning, error, loose]) == """
        /p/LoginView.swift:42:9: error: cannot find 'viewModel' in scope
        error: Unable to find a destination
        /p/Old.swift:7: warning: deprecated
        """)
        #expect(BuildIssuesMapper.rows(for: [error]).first?.copyText == "/p/LoginView.swift:42:9: error: cannot find 'viewModel' in scope")
    }

    @Test func theFailureTextHasEveryErrorOrTheMessage() {
        #expect(BuildIssuesMapper.failureText(message: "LoginView.swift:42:9: error: x", issues: [warning, error, loose]) == "/p/LoginView.swift:42:9: error: cannot find 'viewModel' in scope\nerror: Unable to find a destination")
        #expect(BuildIssuesMapper.failureText(message: "xcodebuild exited with code 65.", issues: [warning]) == "xcodebuild exited with code 65.")
    }
}
