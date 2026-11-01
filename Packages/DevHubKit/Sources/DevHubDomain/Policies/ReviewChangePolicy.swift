import Foundation

package enum ReviewChangePolicy {
    package static let requestLimit = 200

    package static func fingerprint(of file: PullRequestFileDiff) -> String {
        let changed = file.diff.lines.filter(isChange)
        guard file.diff.isBinary == false, file.isTooLarge == false, changed.isEmpty == false else {
            return "\(file.kind)-\(file.additions)-\(file.deletions)"
        }
        return String(fnv1a(changed.joined(separator: "\n")), radix: 16)
    }

    package static func fingerprints(of files: [PullRequestFileDiff]) -> [String: String] {
        Dictionary(files.map { ($0.path, fingerprint(of: $0)) }, uniquingKeysWith: { first, _ in first })
    }

    package static func reviewed(_ snapshot: ReviewSnapshot?, fingerprints: [String: String], at date: Date) -> ReviewSnapshot {
        ReviewSnapshot(reviewedAt: date, files: fingerprints, viewed: snapshot?.viewed ?? [:], updatedAt: date)
    }

    package static func changedPaths(since snapshot: ReviewSnapshot?, paths: [String], fingerprints: [String: String]) -> [String] {
        guard let snapshot, snapshot.reviewedAt != nil else { return [] }
        return paths.filter { snapshot.files[$0] != fingerprints[$0] }
    }

    package static func viewedPaths(in snapshot: ReviewSnapshot?, fingerprints: [String: String]) -> Set<String> {
        guard let snapshot else { return [] }
        return Set(fingerprints.filter { snapshot.viewed[$0.key] == $0.value }.keys)
    }

    package static func settingViewed(_ isViewed: Bool, path: String, fingerprint: String?, in snapshot: ReviewSnapshot?, at date: Date) -> ReviewSnapshot {
        var updated = snapshot ?? ReviewSnapshot(reviewedAt: nil, files: [:], viewed: [:], updatedAt: date)
        updated.viewed[path] = isViewed ? fingerprint : nil
        updated.updatedAt = date
        return updated
    }

    package static func isEveryFileViewed(_ viewed: Set<String>, paths: [String]) -> Bool {
        paths.isEmpty == false && paths.allSatisfy { viewed.contains($0) }
    }

    package static func pruned(_ snapshots: [String: ReviewSnapshot]) -> [String: ReviewSnapshot] {
        guard snapshots.count > requestLimit else { return snapshots }
        let kept = snapshots.sorted { $0.value.updatedAt > $1.value.updatedAt }.prefix(requestLimit)
        return Dictionary(uniqueKeysWithValues: kept.map { ($0.key, $0.value) })
    }

    private static func isChange(_ line: String) -> Bool {
        guard line.hasPrefix("+++") == false, line.hasPrefix("---") == false else { return false }
        return line.hasPrefix("+") || line.hasPrefix("-")
    }

    private static func fnv1a(_ text: String) -> UInt64 {
        text.utf8.reduce(UInt64(14_695_981_039_346_656_037)) { hash, byte in
            (hash ^ UInt64(byte)) &* 1_099_511_628_211
        }
    }
}
