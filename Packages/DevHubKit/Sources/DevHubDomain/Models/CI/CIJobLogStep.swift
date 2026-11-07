import Foundation

package struct CIJobLogStep: Hashable, Sendable {
    package let name: String
    package let exitCode: Int?
    package let output: String

    package init(name: String, exitCode: Int?, output: String) {
        self.name = name
        self.exitCode = exitCode
        self.output = output
    }

    package var isFailed: Bool {
        (exitCode ?? 0) != 0
    }
}
