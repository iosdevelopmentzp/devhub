import Foundation

package enum DiffFontSizePolicy {
    package static let standard = 11
    package static let range = 9...20

    package static func clamped(_ size: Int) -> Int {
        min(max(size, range.lowerBound), range.upperBound)
    }

    package static func changed(_ size: Int, by step: Int) -> Int {
        clamped(size + step)
    }
}
