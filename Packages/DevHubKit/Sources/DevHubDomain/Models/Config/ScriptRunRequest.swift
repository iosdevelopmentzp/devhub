import Foundation

package struct ScriptRunRequest: Hashable, Sendable {
    package var executable: String
    package var arguments: [String]
    package var cwd: String?
    package var environment: [String: String]
    package var timeout: Duration?

    package init(
        executable: String,
        arguments: [String],
        cwd: String?,
        environment: [String: String],
        timeout: Duration? = nil
    ) {
        self.executable = executable
        self.arguments = arguments
        self.cwd = cwd
        self.environment = environment
        self.timeout = timeout
    }
}
