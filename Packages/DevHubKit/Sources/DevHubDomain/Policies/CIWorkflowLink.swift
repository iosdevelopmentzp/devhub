import Foundation

package enum CIWorkflowLink {
    package struct Link: Hashable, Sendable {
        package let workflowID: String
        package let slug: String?

        package init(workflowID: String, slug: String?) {
            self.workflowID = workflowID
            self.slug = slug
        }
    }

    package static func parse(_ url: String?) -> Link? {
        guard let url, url.contains("circleci") else { return nil }
        let parts = url.split(separator: "/").map(String.init)
        guard let workflowsIndex = parts.firstIndex(where: { $0 == "workflows" || $0 == "workflow" }), workflowsIndex + 1 < parts.count else { return nil }
        let workflowID = parts[workflowsIndex + 1].split(separator: "?").first.map(String.init) ?? ""
        guard isUUID(workflowID) else { return nil }
        return Link(workflowID: workflowID, slug: slug(in: parts))
    }

    private static func slug(in parts: [String]) -> String? {
        guard let index = parts.firstIndex(of: "pipelines"), index + 3 < parts.count else { return nil }
        let provider = parts[index + 1]
        let owner = parts[index + 2]
        let name = parts[index + 3]
        guard provider.isEmpty == false, owner.isEmpty == false, name.isEmpty == false, Int(name) == nil else { return nil }
        switch provider {
        case "github", "gh": return "gh/\(owner)/\(name)"
        case "bitbucket", "bb": return "bb/\(owner)/\(name)"
        default: return "\(provider)/\(owner)/\(name)"
        }
    }

    private static func isUUID(_ text: String) -> Bool {
        text.count == 36 && text.split(separator: "-").map(\.count) == [8, 4, 4, 4, 12]
    }
}
