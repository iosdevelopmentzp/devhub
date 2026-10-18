import Foundation

package struct NetworkConfig: Codable, Hashable, Sendable {
    package var baseURLVariable: String? = nil
    package var mocksFolder: String? = nil

    package init(
        baseURLVariable: String? = nil,
        mocksFolder: String? = nil
    ) {
        self.baseURLVariable = baseURLVariable
        self.mocksFolder = mocksFolder
    }
}
