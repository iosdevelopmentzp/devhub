import Foundation
import DevHubDomain
import DevHubUI

enum TestRunPanelMapper {
    static func model(for run: TestRun) -> TestRunPanelModel {
        let counts = TestRunText.counts(passed: run.passed, failed: run.failed, skipped: run.skipped)
        let failures = rows(for: run.failures)
        let issues = BuildIssuesMapper.rows(for: run.issues)
        var model = TestRunPanelModel(
            title: "",
            detail: nil,
            icon: "checkmark.diamond",
            tint: .blue,
            isRunning: run.isRunning,
            step: nil,
            failuresTitle: failures.isEmpty ? nil : CountText.count(failures.count, "failed test"),
            failures: failures,
            issuesTitle: issues.isEmpty ? nil : BuildIssuesMapper.title(for: run.issues),
            issues: issues,
            resultBundlePath: run.resultBundlePath,
            canRunAgain: run.isRunning == false,
            canFix: run.isRunning == false && (run.failures.isEmpty == false || run.issues.isEmpty == false)
        )
        switch run.phase {
        case .running(let step):
            model.title = "Testing \(run.scheme) on \(run.simulatorName)…"
            model.step = step
            model.detail = run.total > 0 ? counts : nil
        case .finished(let status, let date):
            model.title = status == .passed ? "Tests passed · \(run.scheme)" : "Tests failed · \(run.scheme)"
            model.icon = status == .passed ? "checkmark.diamond.fill" : "xmark.diamond.fill"
            model.tint = status == .passed ? .green : .red
            model.detail = [counts, DurationFormat.text(date.timeIntervalSince(run.startedAt)), run.simulatorName].joined(separator: " · ")
        case .notRun(let message, _):
            model.title = "Tests did not run · \(run.scheme)"
            model.icon = "exclamationmark.triangle.fill"
            model.tint = .orange
            model.detail = message
        }
        return model
    }

    static func rows(for failures: [TestFailure]) -> [TestFailureRowModel] {
        failures.enumerated().map { index, failure in
            let location = failure.file.map { file in failure.line.map { "\(file):\($0)" } ?? file }
            return TestFailureRowModel(
                id: index,
                test: failure.test,
                location: location,
                message: failure.message,
                path: failure.path,
                line: failure.line,
                hint: failure.path.map { path in "Open \(path)" + (failure.line.map { " at line \($0)" } ?? "") } ?? failure.message
            )
        }
    }
}
