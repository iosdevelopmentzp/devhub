import Foundation
import DevHubDomain
import DevHubUI

enum CIDiagnosticsBuilder {
    struct Facts {
        var appVersion: String
        var date: Date
        var provider: CIProvider?
        var slug: String?
        var checkoutPath: String
        var ciConfig: CIConfig?
        var hostKind: CodeHostKind?
        var currentBranch: String?
        var baseBranch: String
        var toolState: CIToolState?
        var toolError: String?
        var snapshot: CIDiagnosticsSnapshot
        var failures: [ActivityEvent]
        var commands: [CommandLog.Entry]
    }

    static let commandLimit = 40
    static let failureLimit = 20
    static let outputHeadLines = 40
    static let outputTailLines = 40
    private static let ciKinds: Set<NotificationKind> = [.requestChecks, .requestChecksPassed, .requestApprovals, .baseBranchChecks]

    static func text(_ facts: Facts) -> String {
        var lines = [
            "DevHub CI diagnostics",
            "Date: \(ISOTimestamp.text(facts.date))",
            "DevHub: \(facts.appVersion)",
            "",
            "## Project",
            "Provider: \(facts.provider?.rawValue ?? "none")",
            "Slug: \(facts.slug ?? "none")",
            "Checkout: \(facts.checkoutPath)",
            "Host: \(facts.hostKind?.rawValue ?? "unknown")",
            "Config ci: kind=\(facts.ciConfig?.kind ?? "-") project=\(facts.ciConfig?.project ?? "-")",
            "Branch: \(facts.currentBranch ?? "none"), base: \(facts.baseBranch)",
            "CLI: \(toolText(facts))",
        ]
        if let reference = facts.snapshot.requestReference {
            lines.append("")
            lines.append("## Workflows of \(reference)")
            lines += workflowLines(facts.snapshot.requestWorkflows, errors: facts.snapshot.requestWorkflowErrors)
        }
        lines.append("")
        lines.append("## Latest run of the branch")
        lines += runLines(facts.snapshot.branchRun, workflows: facts.snapshot.branchWorkflows)
        lines.append("")
        lines.append("## Latest run of the base branch")
        lines += runLines(facts.snapshot.baseRun, workflows: facts.snapshot.baseWorkflows)
        lines.append("")
        lines.append("## Recent CI failures")
        lines += facts.failures.isEmpty ? ["none"] : facts.failures.map { "\(ISOTimestamp.text($0.date)) \($0.title)\($0.detail.isEmpty ? "" : " — \($0.detail)")" }
        lines.append("")
        lines.append("## Commands (last \(facts.commands.count) of circleci)")
        for entry in facts.commands {
            lines.append("")
            lines += commandLines(entry)
        }
        return lines.joined(separator: "\n") + "\n"
    }

    static func ciCommands(in entries: [CommandLog.Entry]) -> [CommandLog.Entry] {
        Array(entries.filter { tool(of: $0.command) == "circleci" }.suffix(commandLimit))
    }

    static func ciFailures(in events: [ActivityEvent]) -> [ActivityEvent] {
        Array(events.filter { event in
            guard event.outcome == .failure else { return false }
            if let kind = event.kind, ciKinds.contains(kind) { return true }
            let text = "\(event.title) \(event.detail)"
            return text.localizedCaseInsensitiveContains("circleci") || event.title.hasPrefix("CI of ") || event.title.hasPrefix("Auto re-run")
        }.prefix(failureLimit))
    }

    private static func tool(of command: String) -> String {
        guard let first = command.split(separator: " ").first else { return "" }
        return URL(fileURLWithPath: String(first)).lastPathComponent
    }

    private static func toolText(_ facts: Facts) -> String {
        if let error = facts.toolError { return "unavailable (\(error))" }
        guard let state = facts.toolState else { return "not checked" }
        guard state.isInstalled else { return "not installed" }
        return "circleci \(state.version ?? "unknown version"), \(state.isLoggedIn ? "logged in" : "not logged in")"
    }

    private static func workflowLines(_ workflows: [CIWorkflow], errors: [String: String]) -> [String] {
        var lines = workflows.isEmpty ? ["none"] : []
        for workflow in workflows {
            lines.append("\(workflow.name.isEmpty ? "workflow" : workflow.name) \(workflow.status.name) id=\(workflow.id) run=\(workflow.runID ?? "-")")
            for job in workflow.jobs {
                lines.append("  job \(job.name) \(job.status.name)\(job.isApproval ? " (approval)" : "") id=\(job.id)")
            }
        }
        for (id, message) in errors.sorted(by: { $0.key < $1.key }) {
            lines.append("error \(id): \(message)")
        }
        return lines
    }

    private static func runLines(_ run: CIRun?, workflows: [CIWorkflow]) -> [String] {
        guard let run else { return ["none"] }
        var lines = ["\(run.id) \(run.status.name) branch=\(run.branch ?? "-") rev=\(run.revision ?? "-") created=\(run.createdAt.map(ISOTimestamp.text) ?? "-") subject=\(run.subject ?? "-")"]
        lines += workflows.map { "  workflow \($0.name.isEmpty ? "workflow" : $0.name) \($0.status.name) id=\($0.id)" }
        return lines
    }

    private static func commandLines(_ entry: CommandLog.Entry) -> [String] {
        CommandLogText.lines(entry, head: outputHeadLines, tail: outputTailLines)
    }
}
