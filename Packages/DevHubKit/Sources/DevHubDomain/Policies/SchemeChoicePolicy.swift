import Foundation

package enum SchemeChoicePolicy {

    package static func choose(available: [String], saved: String?, current: String, projectDefault: String) -> String? {
        if let saved, available.contains(saved) {
            return saved
        }
        guard available.isEmpty == false, available.contains(current) == false else { return nil }
        return available.contains(projectDefault) ? projectDefault : (available.first ?? projectDefault)
    }
}
