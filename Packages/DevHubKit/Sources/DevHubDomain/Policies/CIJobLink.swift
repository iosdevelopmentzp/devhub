import Foundation

package enum CIJobLink {

    package static func url(base: URL?, slug: String?, pipelineNumber: Int?, workflowID: String, jobNumber: Int?) -> URL? {
        guard let base, let path = vcsPath(slug: slug), let pipelineNumber, let jobNumber else { return nil }
        return URL(string: "/pipelines/\(path)/\(pipelineNumber)/workflows/\(workflowID)/jobs/\(jobNumber)", relativeTo: base)?.absoluteURL
    }

    package static func pipelinesURL(base: URL?, slug: String?, branch: String) -> URL? {
        guard let base, let path = vcsPath(slug: slug) else { return nil }
        var components = URLComponents(url: base, resolvingAgainstBaseURL: false)
        components?.path = "/pipelines/\(path)"
        components?.queryItems = [URLQueryItem(name: "branch", value: branch)]
        return components?.url
    }

    package static func vcsPath(slug: String?) -> String? {
        guard let slug else { return nil }
        let parts = slug.split(separator: "/").map(String.init)
        guard parts.count == 3, parts.allSatisfy({ $0.isEmpty == false }) else { return nil }
        let provider = switch parts[0] {
        case "gh": "github"
        case "bb": "bitbucket"
        default: parts[0]
        }
        return "\(provider)/\(parts[1])/\(parts[2])"
    }
}
