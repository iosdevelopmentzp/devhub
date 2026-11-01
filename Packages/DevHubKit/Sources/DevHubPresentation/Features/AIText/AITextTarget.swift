import Foundation

enum AITextTarget: Hashable {
    case commitMessage(path: String)
    case newRequest(branch: String)
    case explain(iid: Int)
}
