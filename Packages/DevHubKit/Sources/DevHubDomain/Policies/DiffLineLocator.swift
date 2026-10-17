import Foundation

package enum DiffLineLocator {

    package static func index(ofLine line: Int, isOld: Bool, in lines: [String]) -> Int? {
        DiffLineNumbering.numbers(for: lines).firstIndex { (isOld ? $0.old : $0.new) == line }
    }
}
