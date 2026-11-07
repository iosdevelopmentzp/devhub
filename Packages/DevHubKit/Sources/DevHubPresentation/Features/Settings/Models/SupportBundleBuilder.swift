import Foundation
import DevHubDomain
import DevHubUI

enum SupportBundleBuilder {
    struct Facts {
        var appVersion: String
        var systemVersion: String
        var date: Date
        var settings: AppSettings
        var projectKind: String?
        var scheme: String?
        var bundleID: String?
        var configIssues: [ConfigIssue]
        var tools: [ToolStatus]
        var ciProvider: String?
        var ciSlug: String?
        var ciTool: String
        var crash: CrashReport?
        var events: [ActivityEvent]
        var commands: [CommandLog.Entry]
    }

    static let commandLimit = 100
    static let eventLimit = 50
    static let outputHeadLines = 20
    static let outputTailLines = 20

    static func text(_ facts: Facts) -> String {
        var lines = [
            "DevHub support bundle",
            "Date: \(ISOTimestamp.text(facts.date))",
            "DevHub: \(facts.appVersion.isEmpty ? "unknown" : facts.appVersion)",
            "macOS: \(facts.systemVersion)",
            "",
            "## Settings",
        ]
        lines += settingsLines(facts.settings)
        lines += [
            "",
            "## Project",
            "Kind: \(facts.projectKind ?? "not set")",
            "Scheme: \(facts.scheme ?? "none")",
            "Bundle: \(facts.bundleID ?? "none")",
        ]
        lines += facts.configIssues.isEmpty ? ["Config problems: none"] : ["Config problems:"] + facts.configIssues.map { "- \($0.layer.rawValue) \($0.fileName): \($0.message)" }
        lines += ["", "## Tools"]
        lines += facts.tools.isEmpty ? ["not checked"] : facts.tools.map(toolLine)
        lines += [
            "",
            "## CI",
            "Provider: \(facts.ciProvider ?? "none")",
            "Slug: \(facts.ciSlug ?? "none")",
            "CLI: \(facts.ciTool)",
            "",
            "## Last DevHub crash",
        ]
        lines += facts.crash.map(AppCrashText.lines) ?? ["none"]
        let events = facts.events.prefix(eventLimit)
        lines += ["", "## Recent (last \(events.count))"]
        lines += events.isEmpty ? ["none"] : events.map(eventLine)
        let commands = facts.commands.suffix(commandLimit)
        lines += ["", "## Commands (last \(commands.count))"]
        for entry in commands {
            lines.append("")
            lines += CommandLogText.lines(entry, head: outputHeadLines, tail: outputTailLines)
        }
        return lines.joined(separator: "\n") + "\n"
    }

    private static func settingsLines(_ settings: AppSettings) -> [String] {
        let muted = settings.mutedNotifications.map(\.rawValue).sorted()
        return [
            "Window: \(settings.windowMode.rawValue), Dock icon: \(onOff(settings.showDockIcon))",
            "Editor: \(settings.editor), terminal: \(settings.terminal)",
            "Usage strip: \(onOff(settings.showUsageStrip)), usage in the menu bar: \(onOff(settings.showUsageInMenuBar))",
            "Review count in the menu bar: \(onOff(settings.showReviewCountInMenuBar)), CI state in the menu bar: \(onOff(settings.showCIStateInMenuBar))",
            "Review reminder: \(settings.reviewReminderHours == 0 ? "off" : "\(settings.reviewReminderHours) h"), remember reviews: \(onOff(settings.remembersReviews))",
            "AI text tool: \(settings.aiTextProvider.rawValue), auto fetch: \(settings.autoFetchMinutes == 0 ? "off" : "\(settings.autoFetchMinutes) min")",
            "Notifications while the panel is closed: \(onOff(settings.notifyWhenPanelClosed)), muted: \(muted.isEmpty ? "none" : muted.joined(separator: ", "))",
        ]
    }

    private static func toolLine(_ status: ToolStatus) -> String {
        guard status.isInstalled else { return "\(status.tool.name): missing" }
        let latest = status.latestVersion.map { ", latest \($0)" } ?? ""
        return "\(status.tool.name): \(status.version ?? "unknown version")\(latest) at \(status.path ?? "-")"
    }

    private static func eventLine(_ event: ActivityEvent) -> String {
        let detail = event.detail.isEmpty ? "" : " — \(event.detail)"
        return "\(ISOTimestamp.text(event.date)) \(outcome(event.outcome)) \(event.title)\(detail)"
    }

    private static func outcome(_ outcome: ActivityEvent.Outcome) -> String {
        switch outcome {
        case .success: "ok"
        case .failure: "failed"
        case .info: "info"
        }
    }

    private static func onOff(_ value: Bool) -> String {
        value ? "on" : "off"
    }
}
