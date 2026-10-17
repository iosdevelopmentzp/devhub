import Foundation
import Testing
@testable import DevHubDomain

@Suite struct JSONPatcherTests {
    private let body = Data(#"{"data":{"profile":{"isVIP":false,"balance":120,"name":"Ann"},"chats":[{"unread":3},{"unread":5}]}}"#.utf8)

    @Test func replacesANestedValue() throws {
        let result = try object(JSONPatcher.apply([JSONPatchOperation(keyPath: "data.profile.isVIP", value: "true")], to: body))

        let profile = try #require((result["data"] as? [String: Any])?["profile"] as? [String: Any])
        #expect(profile["isVIP"] as? Bool == true)
        #expect(profile["balance"] as? Int == 120)
    }

    @Test func replacesAnArrayItemByIndex() throws {
        let result = try object(JSONPatcher.apply([JSONPatchOperation(keyPath: "data.chats[1].unread", value: "0")], to: body))

        let chats = try #require((result["data"] as? [String: Any])?["chats"] as? [[String: Any]])
        #expect(chats.map { $0["unread"] as? Int } == [3, 0])
    }

    @Test func removesAKey() throws {
        let result = try object(JSONPatcher.apply([JSONPatchOperation(keyPath: "data.profile.name", value: nil)], to: body))

        let profile = try #require((result["data"] as? [String: Any])?["profile"] as? [String: Any])
        #expect(profile["name"] == nil)
        #expect(profile.count == 2)
    }

    @Test func replaceOnAMissingPathCreatesTheObjects() throws {
        let result = try object(JSONPatcher.apply([JSONPatchOperation(keyPath: "data.wallet.coins", value: "0")], to: body))

        let wallet = try #require((result["data"] as? [String: Any])?["wallet"] as? [String: Any])
        #expect(wallet["coins"] as? Int == 0)
    }

    @Test func removeOnAMissingPathAndAnOutOfBoundsIndexChangeNothing() throws {
        let operations = [
            JSONPatchOperation(keyPath: "data.missing.key", value: nil),
            JSONPatchOperation(keyPath: "data.chats[9].unread", value: "1")
        ]

        let result = try object(JSONPatcher.apply(operations, to: body))

        #expect(NSDictionary(dictionary: result).isEqual(to: try object(body)))
    }

    @Test func plainTextValueBecomesAString() throws {
        let result = try object(JSONPatcher.apply([JSONPatchOperation(keyPath: "data.profile.name", value: "Bob Smith")], to: body))

        #expect(((result["data"] as? [String: Any])?["profile"] as? [String: Any])?["name"] as? String == "Bob Smith")
    }

    @Test func objectValueIsInserted() throws {
        let result = try object(JSONPatcher.apply([JSONPatchOperation(keyPath: "data.banner", value: #"{"title":"Sale"}"#)], to: body))

        #expect(((result["data"] as? [String: Any])?["banner"] as? [String: Any])?["title"] as? String == "Sale")
    }

    @Test func nonJSONBodyIsUntouched() {
        let text = Data("<html>no</html>".utf8)

        #expect(JSONPatcher.apply([JSONPatchOperation(keyPath: "a", value: "1")], to: text) == text)
        #expect(JSONPatcher.isJSON(text) == false)
        #expect(JSONPatcher.isJSON(body))
    }

    @Test func noOperationsKeepsTheOriginalBytes() {
        #expect(JSONPatcher.apply([], to: body) == body)
    }

    private func object(_ data: Data) throws -> [String: Any] {
        try #require(try JSONSerialization.jsonObject(with: data) as? [String: Any])
    }
}
