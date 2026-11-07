import Foundation

struct AppIdentity: Equatable {
    var version: String
    var systemVersion: String
    var processName: String
    var bundleID: String?
    var home: String
}
