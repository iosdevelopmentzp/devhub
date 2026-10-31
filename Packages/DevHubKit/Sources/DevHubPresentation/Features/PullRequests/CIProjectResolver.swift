import Foundation
import DevHubDomain

@MainActor
final class CIProjectResolver {
    private let config: ConfigStore
    private let worktrees: any WorktreeLookup
    private let remote: any CodeHostLookup
    private let tools: any ToolLocating
    private var cache: CIProject?
    private var subscription: SubscriptionToken?

    init(config: ConfigStore, worktrees: any WorktreeLookup, remote: any CodeHostLookup, tools: any ToolLocating, events: AppEvents) {
        self.config = config
        self.worktrees = worktrees
        self.remote = remote
        self.tools = tools
        subscription = events.subscribe { [weak self] event in
            guard let self else { return }
            guard case .projectChanged = event else { return }
            cache = nil
        }
    }

    var checkoutPath: String {
        worktrees.mainCheckoutPath
    }

    var provider: CIProvider? {
        let hasConfigFile = tools.fileExists(atPath: CIPolicy.circleCIConfigPath(checkoutPath: worktrees.mainCheckoutPath))
        return CIPolicy.provider(config: config.resolved.project.ci, hasCircleCIConfig: hasConfigFile)
    }

    func hasProvider(for jobs: [PipelineJob]) -> Bool {
        guard jobs.contains(where: { $0.ciWorkflowID != nil }) else { return false }
        return provider != nil
    }

    func project(for jobs: [PipelineJob]) -> CIProject {
        if let cache {
            return cache
        }
        let linkSlug = jobs.lazy.compactMap { CIWorkflowLink.parse($0.webURL?.absoluteString)?.slug }.first
        let remoteSlug = remote.current.flatMap { $0.kind == .github ? "gh/\($0.path)" : nil }
        let slug = config.resolved.project.ci?.project ?? linkSlug ?? remoteSlug
        let project = CIProject(checkoutPath: worktrees.mainCheckoutPath, slug: slug)
        if slug != nil {
            cache = project
        }
        return project
    }
}
