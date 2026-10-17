import Foundation
import DevHubDomain
import DevHubMocks
import DevHubUI

extension PresentationAssembly {

    static func preview() -> PresentationAssembly {
        let ports = Ports.mock()
        let assembly = PresentationAssembly(
            ports: ports,
            useCases: UseCases(ports: ports),
            store: InMemoryKeyValueStore(),
            commandLog: CommandLog(),
            projects: MockData.projects,
            selectedProjectID: nil,
            settings: AppSettings(),
            recentEvents: MockData.recentEvents
        )
        assembly.worktrees.worktrees = MockData.worktrees
        assembly.worktrees.derivedDataSizes = MockData.derivedDataSizes
        assembly.simulators.groups = MockData.simulatorGroups
        assembly.identity.identities = MockData.identities
        assembly.usage.usage = MockData.usage
        return assembly
    }
}
