import SwiftUI

package extension View {

    func hint(_ text: String?) -> some View {
        modifier(HintModifier(text: text))
    }

    func hintWhenTruncated(_ fullText: String) -> some View {
        modifier(TruncationHintModifier(fullText: fullText, suffix: nil))
    }

    func hintWhenTruncated(_ fullText: String, adding suffix: String) -> some View {
        modifier(TruncationHintModifier(fullText: fullText, suffix: suffix))
    }
}
