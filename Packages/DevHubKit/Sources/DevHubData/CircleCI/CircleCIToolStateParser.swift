import Foundation
import DevHubDomain

enum CircleCIToolStateParser {
    private struct Version: Decodable {
        let version: String?
    }

    private struct Settings: Decodable {
        let tokenSet: Bool?
    }

    static func version(from result: ShellResult) -> String? {
        if let decoded = try? CircleCIJSON.decode(Version.self, from: Data(result.stdout.utf8)), let version = decoded.version {
            return version
        }
        let text = result.stdout + "\n" + result.stderr
        guard let range = text.range(of: #"\d+(\.\d+)+"#, options: .regularExpression) else { return nil }
        return String(text[range])
    }

    static func isLoggedIn(_ result: ShellResult) -> Bool {
        guard result.exitCode == 0, let settings = try? CircleCIJSON.decode(Settings.self, from: Data(result.stdout.utf8)) else { return false }
        return settings.tokenSet ?? false
    }
}
