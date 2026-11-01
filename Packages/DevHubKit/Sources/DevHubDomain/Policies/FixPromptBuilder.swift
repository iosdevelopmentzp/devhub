import Foundation

package enum FixPromptBuilder {

    package static func tests(scheme: String, checkoutName: String, passed: Int, failed: Int, skipped: Int, failures: [TestFailure], issues: [BuildIssue]) -> String {
        var lines = [
            "# Failed tests of \(scheme) in \(checkoutName)",
            "",
            "The run gave \(passed) passed, \(failed) failed and \(skipped) skipped tests.",
            "",
        ]
        if failures.isEmpty == false {
            lines += ["## Failed tests", ""]
            for (offset, failure) in failures.enumerated() {
                lines += block(failure, number: offset + 1)
            }
        }
        lines += issueLines(issues)
        lines += [
            "## What to do",
            "",
            "1. Make every failed test above pass in this checkout. Keep each change small and in the style of the code around it.",
            "2. Fix the code under test first. Change a test only when the test itself is wrong, and write down why.",
            "3. Build and run the tests the project uses.",
            "4. At the end, list each failed test with one line: what you changed, or why you did not.",
        ]
        return lines.joined(separator: "\n") + "\n"
    }

    package static func build(scheme: String, checkoutName: String, issues: [BuildIssue]) -> String {
        var lines = [
            "# Build errors of \(scheme) in \(checkoutName)",
            "",
            "The build of \(scheme) failed with \(issues.filter { $0.severity == .error }.count) errors.",
            "",
        ]
        lines += issueLines(issues)
        lines += [
            "## What to do",
            "",
            "1. Make the build pass in this checkout. Keep each change small and in the style of the code around it.",
            "2. Build with the scheme above, then run the tests the project uses.",
            "3. At the end, list each error with one line: what you changed.",
        ]
        return lines.joined(separator: "\n") + "\n"
    }

    package static func crash(_ report: CrashReport, checkoutName: String) -> String {
        var lines = [
            "# Crash of \(report.processName) in \(checkoutName)",
            "",
            "The app \(report.bundleID ?? report.processName)\(report.appVersion.map { " \($0)" } ?? "") crashed on a simulator.",
            "",
            "- Exception: \(CrashReportPolicy.exception(of: report) ?? "unknown")\(report.subtype.map { ", \($0)" } ?? "")",
            "- Report: \(report.path)",
        ]
        if report.messages.isEmpty == false {
            lines += ["", "## Messages", ""]
            lines += report.messages.map { "    " + $0 }
        }
        lines += ["", "## Crashed thread", ""]
        lines += report.frames.prefix(20).enumerated().map { index, frame in
            let place = CrashReportPolicy.place(of: frame).map { " at \($0)" } ?? ""
            return "\(index). \(frame.image) \(frame.symbol ?? "?")\(place)\(frame.isApp ? " (app)" : "")"
        }
        lines += [
            "",
            "## What to do",
            "",
            "1. Find the cause of the crash in this checkout. Start at the first frame marked (app).",
            "2. Fix it with a small change in the style of the code around it, and add a test when the code allows it.",
            "3. At the end, say what caused the crash and what you changed.",
        ]
        return lines.joined(separator: "\n") + "\n"
    }

    package static func fileName(forCrashOf processName: String) -> String {
        "fix-crash-\(slug(processName))"
    }

    package static func fileName(forTestsOf checkoutName: String) -> String {
        "fix-tests-\(slug(checkoutName))"
    }

    package static func fileName(forBuildOf scheme: String) -> String {
        "fix-build-\(slug(scheme))"
    }

    private static func block(_ failure: TestFailure, number: Int) -> [String] {
        var title = "## Failure \(number)"
        if let test = failure.test {
            title += ": `\(test)`"
        }
        if let file = failure.file {
            title += " (`\(file)" + (failure.line.map { ":\($0)" } ?? "") + "`)"
        }
        return [title, "", quoted(failure.message), ""]
    }

    private static func issueLines(_ issues: [BuildIssue]) -> [String] {
        let errors = issues.filter { $0.severity == .error }
        let warnings = issues.filter { $0.severity == .warning }
        var lines: [String] = []
        if errors.isEmpty == false {
            lines += ["## Compiler errors", ""] + errors.map(line) + [""]
        }
        if warnings.isEmpty == false {
            lines += ["## Warnings (fix only when they touch the errors above)", ""] + warnings.map(line) + [""]
        }
        return lines
    }

    private static func line(_ issue: BuildIssue) -> String {
        guard let path = issue.path else { return "- \(issue.message)" }
        return "- `\(path)" + (issue.line.map { ":\($0)" } ?? "") + "`: \(issue.message)"
    }

    private static func quoted(_ text: String) -> String {
        text.split(separator: "\n", omittingEmptySubsequences: false).map { "> \($0)" }.joined(separator: "\n")
    }

    private static func slug(_ name: String) -> String {
        let allowed = name.lowercased().map { $0.isLetter || $0.isNumber ? $0 : "-" }
        let collapsed = String(allowed).split(separator: "-", omittingEmptySubsequences: true).joined(separator: "-")
        return collapsed.isEmpty ? "checkout" : collapsed
    }
}
