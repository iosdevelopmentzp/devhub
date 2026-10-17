import Foundation
import DevHubDomain

enum CurlCommandBuilder {

    static func command(for request: NetworkRequest) -> String {
        var head = ["curl"]
        let method = request.method.uppercased()
        if method.isEmpty == false, method != "GET" {
            head.append("-X \(method)")
        }
        head.append(quoted(request.url))
        var lines = [head.joined(separator: " ")]
        if request.requestBody.isEmpty == false {
            lines.append("-H \(quoted("Content-Type: application/json"))")
            lines.append("--data-raw \(quoted(request.requestBody))")
        }
        return lines.joined(separator: " \\\n  ")
    }

    private static func quoted(_ value: String) -> String {
        "'" + value.replacingOccurrences(of: "'", with: #"'\''"#) + "'"
    }
}
