import Foundation
import DevHubDomain

enum TrackingInfoParser {
    struct Tracking: Sendable {
        var upstream: String?
        var isGone: Bool
        var ahead: Int
        var behind: Int
    }

    static func tracking(upstream: String, track: String) -> Tracking {
        Tracking(
            upstream: upstream.isEmpty ? nil : upstream,
            isGone: track == "gone",
            ahead: count(after: "ahead ", in: track),
            behind: count(after: "behind ", in: track)
        )
    }

    static func parse(_ output: String) -> [String: Tracking] {
        var result: [String: Tracking] = [:]
        for line in output.split(separator: "\n") {
            let fields = line.split(separator: "\t", omittingEmptySubsequences: false).map(String.init)
            guard fields.count == 3 else { continue }
            result[fields[0]] = tracking(upstream: fields[1], track: fields[2])
        }
        return result
    }

    static func count(after label: String, in track: String) -> Int {
        guard let range = track.range(of: label) else { return 0 }
        return Int(track[range.upperBound...].prefix { $0.isNumber }) ?? 0
    }
}
