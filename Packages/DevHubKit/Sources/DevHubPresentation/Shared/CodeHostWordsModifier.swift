import SwiftUI

struct CodeHostWordsModifier: ViewModifier {
    let remote: CodeHostRemote

    func body(content: Content) -> some View {
        content.environment(\.codeHostWords, remote.words)
    }
}
