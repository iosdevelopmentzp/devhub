import Foundation

package enum MockServerError: LocalizedError, Equatable {
    case prodNotSupported
    case noUpstream(environment: String)
    case noIdentityConfig
    case noSetChosen
    case startFailed(String)

    package var errorDescription: String? {
        switch self {
        case .prodNotSupported:
            "Prod cannot be mocked: Release builds pin certificates and ignore DEVHUB_BASE_URL. Switch the app to qa or dev."
        case .noUpstream(let environment):
            "No mock host is set for the \"\(environment)\" environment. Add it to mockUpstreams in the project's identity settings."
        case .noIdentityConfig:
            "This project has no device identity settings, so DevHub does not know the real API host. Add an identity config first."
        case .noSetChosen:
            "Choose a mock set, or create one, before you turn on Mock mode."
        case .startFailed(let message):
            "The mock server did not start: \(message)"
        }
    }
}
