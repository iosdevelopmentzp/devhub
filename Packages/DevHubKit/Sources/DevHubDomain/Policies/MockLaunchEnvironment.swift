import Foundation

package enum MockLaunchEnvironment {

    package static func baseURL(port: Int) -> String {
        "http://127.0.0.1:\(port)"
    }

    package static func variables(port: Int?, variable: String?) -> [String: String] {
        guard let port, let variable, variable.trimmed.isEmpty == false else { return [:] }
        return [variable: baseURL(port: port)]
    }
}
