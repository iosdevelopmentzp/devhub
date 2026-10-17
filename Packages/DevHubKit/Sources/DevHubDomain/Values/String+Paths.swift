import Foundation

package extension String {

    var abbreviatingHome: String {
        (self as NSString).abbreviatingWithTildeInPath
    }
}
