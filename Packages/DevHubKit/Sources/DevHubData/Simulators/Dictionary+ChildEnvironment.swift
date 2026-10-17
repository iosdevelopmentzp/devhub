import Foundation
import DevHubDomain

extension Dictionary where Key == String, Value == String {

    var childEnvironment: [String: String] {
        Dictionary(uniqueKeysWithValues: map { ("SIMCTL_CHILD_\($0.key)", $0.value) })
    }
}
