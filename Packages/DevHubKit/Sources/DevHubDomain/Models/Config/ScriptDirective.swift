import Foundation

package enum ScriptDirective: Hashable, Sendable {
    case progress(text: String, fraction: Double?)
    case toast(String)
    case copy(String)
    case open(String)
    case notify(title: String, body: String?)
    case refresh([RefreshTarget])
    case error(String)
    case app(String)
    case view(ScriptView)
    case state(AppStateReport)
}
