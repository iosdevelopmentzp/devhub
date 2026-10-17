import Foundation

nonisolated enum PushPayload {
    static let alertTemplate = """
    {
      "aps": {
        "alert": { "title": "Title", "body": "Message" },
        "sound": "default"
      }
    }
    """

    static let silentTemplate = """
    {
      "aps": { "content-available": 1 }
    }
    """

    static func problem(in text: String) -> String? {
        guard let data = text.data(using: .utf8) else { return "The text is not UTF-8." }
        guard let object = try? JSONSerialization.jsonObject(with: data) else { return "This is not valid JSON." }
        guard let dictionary = object as? [String: Any] else { return "The payload must be a JSON object." }
        guard dictionary["aps"] is [String: Any] else { return "The payload needs an \"aps\" object." }
        return nil
    }
}
