import Foundation
import DevHubDomain

enum CircleCIArtifactParser {
    private struct Artifact: Decodable {
        let path: String?
        let url: String?
    }

    private struct Page: Decodable {
        let items: [Artifact]?
        let artifacts: [Artifact]?
    }

    static func artifacts(from data: Data) throws -> [CIArtifact] {
        let dtos: [Artifact]
        if let list = try? CircleCIJSON.decode([Artifact].self, from: data) {
            dtos = list
        } else {
            let page = try CircleCIJSON.decode(Page.self, from: data)
            dtos = page.items ?? page.artifacts ?? []
        }
        return dtos.compactMap { dto in
            guard let path = dto.path, path.isEmpty == false else { return nil }
            return CIArtifact(path: path, url: dto.url.flatMap(URL.init(string:)))
        }
    }
}
