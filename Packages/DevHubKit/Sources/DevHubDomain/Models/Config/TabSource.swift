import Foundation

package struct TabSource: Codable, Hashable, Sendable {
    package var script: String
    package var refresh: String? = nil

    package init(
        script: String,
        refresh: String? = nil
    ) {
        self.script = script
        self.refresh = refresh
    }

    private enum CodingKeys: String, CodingKey {
        case script, refresh
    }

    package init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        script = try container.decode(String.self, forKey: .script)
        refresh = try container.decodeFlexibleString(forKey: .refresh)
    }
}
