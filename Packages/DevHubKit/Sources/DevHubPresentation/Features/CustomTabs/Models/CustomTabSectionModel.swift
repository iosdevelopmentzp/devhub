import Foundation
import DevHubDomain
import DevHubUI

struct CustomTabSectionModel: Identifiable, Equatable {
    enum Content: Equatable {
        case actions([CatalogAction], missing: [String])
        case source(ResolvedAction, refresh: TabRefresh)
        case missingSource(String)
    }

    let id: Int
    let title: String
    let content: Content
}
