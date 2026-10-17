import Foundation

package struct ProfileDefault: Codable, Hashable, Sendable {
    package var suite: String
    package var key: String
    package var value: String
    package var type: String? = nil

    package init(
        suite: String,
        key: String,
        value: String,
        type: String? = nil
    ) {
        self.suite = suite
        self.key = key
        self.value = value
        self.type = type
    }

    private enum CodingKeys: String, CodingKey {
        case suite, key, value, type
    }

    package init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        suite = try container.decode(String.self, forKey: .suite)
        key = try container.decode(String.self, forKey: .key)
        value = try container.decodeFlexibleString(forKey: .value) ?? ""
        type = try container.decodeIfPresent(String.self, forKey: .type)
    }
}
