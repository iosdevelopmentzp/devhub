import Testing
@testable import DevHubDomain

@Suite struct CommandKindTests {
    @Test(arguments: [
        "status", "log", "for-each-ref", "rev-parse", "symbolic-ref", "check-ref-format", "reflog",
        "rev-list", "show-ref", "config", "diff", "cherry", "merge-base", "ls-remote", "remote", "show",
    ])
    func gitReadSubcommandsAreReads(subcommand: String) {
        #expect(CommandKind.classify("git", [subcommand, "--some-flag"]) == .read)
    }

    @Test func gitFlagsBeforeTheSubcommandAreSkipped() {
        #expect(CommandKind.classify("git", ["--no-pager", "log", "-1"]) == .read)
    }

    @Test func gitPathAfterDashCIsTakenAsTheSubcommand() {
        #expect(CommandKind.classify("git", ["-C", "/repo", "status"]) == .action)
    }

    @Test(arguments: ["fetch", "push", "pull", "rebase", "commit", "switch", "stash", "worktree", "clean", "restore"])
    func gitChangingSubcommandsAreActions(subcommand: String) {
        #expect(CommandKind.classify("git", [subcommand]) == .action)
    }

    @Test func gitBranchListingIsARead() {
        #expect(CommandKind.classify("git", ["branch", "--list", "--format=%(refname)"]) == .read)
    }

    @Test(arguments: ["-d", "-D", "-m", "-M", "--delete", "--move", "-u", "--set-upstream-to"])
    func gitBranchWithAMutatingFlagIsAnAction(flag: String) {
        #expect(CommandKind.classify("git", ["branch", flag, "feature"]) == .action)
    }

    @Test func gitWorktreeListIsARead() {
        #expect(CommandKind.classify("git", ["worktree", "list", "--porcelain"]) == .read)
        #expect(CommandKind.classify("git", ["worktree", "add", "../x"]) == .action)
    }

    @Test func gitStashListIsARead() {
        #expect(CommandKind.classify("git", ["stash", "list"]) == .read)
        #expect(CommandKind.classify("git", ["stash", "push"]) == .action)
    }

    @Test func gitWithoutArgumentsIsAnAction() {
        #expect(CommandKind.classify("git", []) == .action)
    }

    @Test(arguments: ["list", "get_app_container", "listapps", "bootstatus"])
    func simctlReadsAreReads(subcommand: String) {
        #expect(CommandKind.classify("xcrun", ["simctl", subcommand, "SIM-1"]) == .read)
    }

    @Test func simctlSpawnDefaultsReadIsARead() {
        #expect(CommandKind.classify("xcrun", ["simctl", "spawn", "SIM-1", "defaults", "read", "suite"]) == .read)
    }

    @Test func simctlSpawnLogIsAnAppLog() {
        #expect(CommandKind.classify("xcrun", ["simctl", "spawn", "SIM-1", "log", "stream"]) == .appLog)
    }

    @Test func otherSimctlCommandsAreActions() {
        #expect(CommandKind.classify("xcrun", ["simctl", "boot", "SIM-1"]) == .action)
        #expect(CommandKind.classify("xcrun", ["simctl", "spawn", "SIM-1", "defaults", "write"]) == .action)
        #expect(CommandKind.classify("xcrun", ["simctl"]) == .action)
        #expect(CommandKind.classify("xcrun", ["xcodebuild", "list"]) == .action)
    }

    @Test func codeHostAPICallsAreReadsUnlessTheyChangeData() {
        for tool in ["gh", "glab"] {
            #expect(CommandKind.classify(tool, ["api", "--hostname", "github.com", "repos/example/app"]) == .read)
            #expect(CommandKind.classify(tool, ["api", "--hostname", "github.com", "-X", "GET", "repos/example/app/pulls", "-f", "state=open"]) == .read)
            #expect(CommandKind.classify(tool, ["api", "--hostname", "github.com", "-X", "PUT", "repos/example/app/pulls/1/merge"]) == .action)
            #expect(CommandKind.classify(tool, ["api", "--hostname", "github.com", "repos/example/app/issues/1/comments", "-f", "body=Hi"]) == .action)
            #expect(CommandKind.classify(tool, ["api", "graphql", "--hostname", "github.com", "-f", "query=query { viewer { login } }"]) == .read)
            #expect(CommandKind.classify(tool, ["api", "graphql", "--hostname", "github.com", "-f", "query= mutation Approve { x }"]) == .action)
        }
        #expect(CommandKind.classify("glab", ["mr", "create"]) == .action)
        #expect(CommandKind.classify("gh", ["pr", "view", "12"]) == .read)
        #expect(CommandKind.classify("gh", ["pr", "checks", "12"]) == .read)
    }

    @Test func xcodebuildShowBuildSettingsIsARead() {
        #expect(CommandKind.classify("xcodebuild", ["-scheme", "App", "-showBuildSettings"]) == .read)
        #expect(CommandKind.classify("xcodebuild", ["-scheme", "App", "build"]) == .action)
    }

    @Test func osascriptClickIsAnAction() {
        #expect(CommandKind.classify("osascript", ["-e", "tell application \"System Events\" to click menu item 1"]) == .action)
    }

    @Test func osascriptSetRunDestinationIsAnAction() {
        #expect(CommandKind.classify("osascript", ["-e", "set active run destination of workspace 1 to d"]) == .action)
    }

    @Test func osascriptQueryIsARead() {
        #expect(CommandKind.classify("osascript", ["-e", "get name of every window"]) == .read)
    }

    @Test(arguments: ["du", "ps", "grep", "plutil", "pgrep", "mdfind", "xcode-select"])
    func plainReadToolsAreReads(executable: String) {
        #expect(CommandKind.classify(executable, ["-x"]) == .read)
    }

    @Test func securityIsASecret() {
        #expect(CommandKind.classify("security", ["find-generic-password", "-w"]) == .secret)
    }

    @Test func ghAuthTokenIsASecret() {
        #expect(CommandKind.classify("gh", ["auth", "token"]) == .secret)
        #expect(CommandKind.classify("gh", ["auth", "status"]) == .read)
        #expect(CommandKind.classify("gh", ["pr", "merge", "12"]) == .action)
    }

    @Test(arguments: ["open", "/bin/zsh", "rm", "claude"])
    func otherExecutablesAreActions(executable: String) {
        #expect(CommandKind.classify(executable, []) == .action)
    }

    @Test func secretsAndAppLogsHideTheirOutput() {
        #expect(CommandKind.secret.hidesOutput)
        #expect(CommandKind.appLog.hidesOutput)
        #expect(CommandKind.read.hidesOutput == false)
        #expect(CommandKind.action.hidesOutput == false)
    }

    @Test func circleCIReadsAreReads() {
        #expect(CommandKind.classify("circleci", ["workflow", "get", "w1", "--json"]) == .read)
        #expect(CommandKind.classify("circleci", ["run", "list", "--branch", "main", "--limit", "10", "--json"]) == .read)
        #expect(CommandKind.classify("circleci", ["job", "output", "list", "j1", "--json"]) == .read)
        #expect(CommandKind.classify("circleci", ["testresult", "list", "j1", "--json"]) == .read)
        #expect(CommandKind.classify("circleci", ["setting", "list", "--json"]) == .read)
        #expect(CommandKind.classify("circleci", ["version", "--json"]) == .read)
        #expect(CommandKind.classify("circleci", ["auth", "me", "--json"]) == .read)
        #expect(CommandKind.classify("circleci", ["api", "api/v2/insights/gh/example/app/flaky-tests"]) == .read)
    }

    @Test func circleCIChangesAreActions() {
        #expect(CommandKind.classify("circleci", ["workflow", "rerun", "w1", "--from-failed", "--json"]) == .action)
        #expect(CommandKind.classify("circleci", ["workflow", "cancel", "w1", "--force"]) == .action)
        #expect(CommandKind.classify("circleci", ["run", "approve", "r1", "--job", "deploy", "--force", "--json"]) == .action)
        #expect(CommandKind.classify("circleci", ["api", "api/v2/project/x/pipeline", "-X", "POST"]) == .action)
        #expect(CommandKind.classify("circleci", ["api", "api/v2/x", "-f", "branch=main"]) == .action)
        #expect(CommandKind.classify("circleci", ["auth", "login"]) == .action)
        #expect(CommandKind.classify("circleci", []) == .action)
    }

    @Test func ffmpegChecksAndProbesAreReads() {
        #expect(CommandKind.classify("/opt/homebrew/bin/ffmpeg", ["-hide_banner", "-version"]) == .read)
        #expect(CommandKind.classify("/opt/homebrew/bin/ffmpeg", ["-hide_banner", "-encoders"]) == .read)
        #expect(CommandKind.classify("/opt/homebrew/bin/ffprobe", ["-v", "error", "-show_format", "/a/clip.mov"]) == .read)
    }

    @Test func anFFmpegCompressionIsAnAction() {
        #expect(CommandKind.classify("/opt/homebrew/bin/ffmpeg", ["-i", "/a/clip.mov", "/a/out.mp4"]) == .action)
        #expect(CommandKind.classify("/opt/homebrew/bin/brew", ["install", "ffmpeg"]) == .action)
    }

    @Test func aFullPathIsClassifiedByItsToolName() {
        #expect(CommandKind.classify("/usr/bin/git", ["status"]) == .read)
        #expect(CommandKind.classify("/usr/bin/security", ["find-generic-password"]) == .secret)
    }
}
