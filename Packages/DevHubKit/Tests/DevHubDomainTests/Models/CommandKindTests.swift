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

    @Test func glabAPIIsARead() {
        #expect(CommandKind.classify("glab", ["api", "projects"]) == .read)
        #expect(CommandKind.classify("glab", ["mr", "create"]) == .action)
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

    @Test(arguments: ["du", "ps", "grep", "plutil", "pgrep"])
    func plainReadToolsAreReads(executable: String) {
        #expect(CommandKind.classify(executable, ["-x"]) == .read)
    }

    @Test func securityIsASecret() {
        #expect(CommandKind.classify("security", ["find-generic-password", "-w"]) == .secret)
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
}
