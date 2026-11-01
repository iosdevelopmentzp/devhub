import Foundation
import DevHubDomain

struct AppDataFileRowModel: Identifiable, Equatable {
    let id: String
    var name: String
    var path: String
    var sizeText: String
    var icon: String
    var hint: String

    static let preview = AppDataFileRowModel(
        id: "/Users/alex/Library/Developer/CoreSimulator/Devices/A/data/Containers/Data/Application/B/Documents",
        name: "Documents",
        path: "/Users/alex/Library/Developer/CoreSimulator/Devices/A/data/Containers/Data/Application/B/Documents",
        sizeText: "1.2 MB",
        icon: "folder",
        hint: "Show in Finder"
    )
}
