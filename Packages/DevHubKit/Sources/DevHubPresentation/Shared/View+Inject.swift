import SwiftUI
import DevHubDomain
import DevHubUI

extension View {

    func inject(_ assembly: PresentationAssembly) -> some View {
        self
            .environment(assembly.commandLog)
            .environment(assembly.session)
            .environment(assembly.navigator)
            .environment(assembly.activity)
            .environment(assembly.toaster)
            .environment(assembly.output)
            .environment(assembly.layout)
            .environment(assembly.settings)
            .environment(assembly.usage)
            .environment(assembly.worktrees)
            .environment(assembly.git)
            .environment(assembly.changes)
            .environment(assembly.history)
            .environment(assembly.mergeRequests)
            .environment(assembly.gitLab)
            .environment(assembly.openMergeRequests)
            .environment(assembly.newMergeRequest)
            .environment(assembly.mergeRequestDetails)
            .environment(assembly.simulators)
            .environment(assembly.identity)
            .environment(assembly.build)
            .environment(assembly.scripts)
            .environment(assembly.logs)
            .environment(assembly.mockSets)
            .environment(assembly.mockServer)
            .environment(assembly.network)
            .environment(assembly.messaging)
            .environment(assembly.claudeSessions)
            .environment(assembly.appActions)
            .environment(\.hintCenter, assembly.hints)
            .environment(\.copyToPasteboard, { value, label in assembly.toaster.copy(value, label: label) })
    }
}
