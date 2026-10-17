import Foundation
import DevHubDomain

enum LaunchOutput {

    static func pid(from output: String) -> Int32? {
        output.split(separator: ":").last.flatMap { Int32($0.trimmingCharacters(in: .whitespacesAndNewlines)) }
    }
}
