import Foundation
import DevHubDomain

struct AppDataPanelModel: Equatable {
    var title: String
    var containerPath: String
    var containerText: String
    var folders: [AppDataFileRowModel]
    var databases: [AppDataFileRowModel]
    var databasesEmptyText: String
    var sections: [AppDefaultsSectionModel]
    var resetConfirmation: String
    var resetWarnings: [String]
    var groupsToggleTitle: String?
    var footnote: String
}
