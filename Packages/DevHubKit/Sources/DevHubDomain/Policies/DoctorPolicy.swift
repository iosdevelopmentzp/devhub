import Foundation

package enum DoctorPolicy {
    package static let timeout: Duration = .seconds(5)

    package static let tools = [
        DoctorTool(name: "git", versionArguments: ["--version"], purpose: "Git tab, worktrees, branches", installCommand: "xcode-select --install"),
        DoctorTool(name: "xcodebuild", versionArguments: ["-version"], purpose: "Build & Run", installCommand: "Install Xcode from the App Store, then: sudo xcode-select -s /Applications/Xcode.app"),
        DoctorTool(name: "xcrun", versionArguments: ["simctl", "help"], purpose: "Simulators, logs, launches (simctl)", installCommand: "sudo xcode-select -s /Applications/Xcode.app"),
        DoctorTool(name: "gh", versionArguments: ["--version"], purpose: "GitHub pull requests", installCommand: "brew install gh && gh auth login"),
        DoctorTool(name: "glab", versionArguments: ["--version"], purpose: "GitLab merge requests", installCommand: "brew install glab && glab auth login"),
        DoctorTool(name: "circleci", versionArguments: ["version"], purpose: "CircleCI workflows, jobs and flaky tests (version 1 or newer)", installCommand: "brew install circleci && circleci auth login", minimumMajorVersion: CIPolicy.minimumVersion, upgradeCommand: "brew upgrade circleci"),
        DoctorTool(name: "copilot", versionArguments: ["--version"], purpose: "Copilot CLI sessions", installCommand: "npm install -g @github/copilot"),
        DoctorTool(name: "claude", versionArguments: ["--version"], purpose: "Claude Code sessions and AI review", installCommand: "npm install -g @anthropic-ai/claude-code"),
        DoctorTool(name: "python3", versionArguments: ["--version"], purpose: "Scripts of the example .devhub folder", installCommand: "xcode-select --install"),
    ]

    package static func isBelow(minimumMajorVersion minimum: Int, version: String) -> Bool {
        guard let major = version.split(separator: ".").first.flatMap({ Int($0.filter(\.isNumber)) }) else { return false }
        return major < minimum
    }

    package static func version(from lines: [String]) -> String? {
        let pattern = #"\d+(\.\d+)+"#
        for line in lines {
            if let range = line.range(of: pattern, options: .regularExpression) {
                return String(line[range])
            }
        }
        return lines.first { $0.trimmed.isEmpty == false }.map { String($0.trimmed.prefix(40)) }
    }
}
