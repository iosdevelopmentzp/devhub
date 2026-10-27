import Foundation
import DevHubDomain

enum GlabDiffRefsParser {
    struct DiffRefs: Equatable {
        let baseSHA: String
        let startSHA: String
        let headSHA: String
    }

    private struct MergeRequestDTO: Decodable {
        let diff_refs: DiffRefsDTO?
    }

    private struct DiffRefsDTO: Decodable {
        let base_sha: String?
        let start_sha: String?
        let head_sha: String?
    }

    static func diffRefs(from data: Data) throws -> DiffRefs {
        let refs = try JSONDecoder().decode(MergeRequestDTO.self, from: data).diff_refs
        guard let base = refs?.base_sha, let start = refs?.start_sha, let head = refs?.head_sha else {
            throw PullRequestError.command("GitLab sent no diff refs for this merge request. Reload it and try again.")
        }
        return DiffRefs(baseSHA: base, startSHA: start, headSHA: head)
    }
}
