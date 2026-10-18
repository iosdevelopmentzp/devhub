import Foundation

package enum MockSetLocation: Hashable, Sendable {
    case defaultFolder(project: String)
    case folder(String)
}
