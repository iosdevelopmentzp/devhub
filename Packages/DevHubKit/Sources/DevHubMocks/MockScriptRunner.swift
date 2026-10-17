import Foundation
import DevHubDomain

struct MockScriptRunner: ScriptRunning {
    func run(_ request: ScriptRunRequest) -> AsyncThrowingStream<ScriptEvent, any Error> {
        AsyncThrowingStream { continuation in
            continuation.yield(.output(#"@devhub {"toast": "Done"}"#))
            continuation.yield(.exited(0))
            continuation.finish()
        }
    }
}
