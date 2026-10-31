import Foundation

package struct CIProject: Hashable, Sendable {
    package let checkoutPath: String
    package let slug: String?

    package init(checkoutPath: String, slug: String?) {
        self.checkoutPath = checkoutPath
        self.slug = slug
    }
}
