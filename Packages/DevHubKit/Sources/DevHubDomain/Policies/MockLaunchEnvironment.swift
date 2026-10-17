import Foundation

package enum MockLaunchEnvironment {
    package static let variable = "DEVHUB_BASE_URL"

    package static func baseURL(port: Int) -> String {
        "http://127.0.0.1:\(port)"
    }

    package static func variables(port: Int?) -> [String: String] {
        guard let port else { return [:] }
        return [variable: baseURL(port: port)]
    }
}
