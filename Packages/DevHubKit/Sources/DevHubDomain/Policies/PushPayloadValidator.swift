import Foundation

package enum PushPayloadValidator {

    package static func error(in payload: String) -> String? {
        guard let data = payload.data(using: .utf8) else { return "Not UTF-8 text" }
        do {
            let object = try JSONSerialization.jsonObject(with: data)
            guard let dictionary = object as? [String: Any] else { return "The payload must be a JSON object" }
            guard dictionary["aps"] != nil else { return "The payload needs an \"aps\" key" }
            return nil
        } catch {
            return "Invalid JSON"
        }
    }
}
