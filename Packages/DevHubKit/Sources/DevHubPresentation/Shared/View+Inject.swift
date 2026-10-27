import SwiftUI
import DevHubDomain
import DevHubUI

extension View {

    func inject(_ assembly: PresentationAssembly) -> some View {
        self
            .environment(assembly.commandLog)
            .environment(assembly.session)
            .environment(assembly.config)
            .environment(assembly.navigator)
            .environment(assembly.activity)
            .environment(assembly.toaster)
            .environment(assembly.notifier)
            .environment(assembly.doctor)
            .environment(assembly.keepAwake)
            .environment(assembly.output)
            .environment(assembly.layout)
            .environment(assembly.settings)
            .environment(assembly.usage)
            .environment(assembly.worktrees)
            .environment(assembly.git)
            .environment(assembly.changes)
            .environment(assembly.history)
            .environment(assembly.branchPullRequest)
            .environment(assembly.pullRequests)
            .environment(assembly.openPullRequests)
            .environment(assembly.newPullRequest)
            .environment(assembly.pullRequestDetails)
            .environment(assembly.simulators)
            .environment(assembly.identity)
            .environment(assembly.build)
            .environment(assembly.simulatorStatuses)
            .environment(assembly.configActions)
            .environment(assembly.logs)
            .environment(assembly.mockSets)
            .environment(assembly.mockServer)
            .environment(assembly.network)
            .environment(assembly.messaging)
            .environment(assembly.aiSessions)
            .environment(assembly.appActions)
            .modifier(CodeHostWordsModifier(remote: assembly.codeHostRemote))
            .environment(\.hintCenter, assembly.hints)
            .environment(\.copyToPasteboard, { value, label in assembly.toaster.copy(value, label: label) })
    }
}
