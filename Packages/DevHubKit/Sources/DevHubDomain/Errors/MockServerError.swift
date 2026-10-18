import Foundation

package enum MockServerError: LocalizedError, Equatable {
    case productionRefused(profile: String)
    case noUpstream(profile: String)
    case noProfile
    case disabled
    case noSetChosen
    case startFailed(String)

    package var errorDescription: String? {
        switch self {
        case .productionRefused(let profile):
            "The \(profile) profile is marked production: DevHub does not send production traffic through the mock server. Choose another profile in the run bar."
        case .noUpstream(let profile):
            "The \(profile) profile has no upstream. Add the real server URL as launch.profiles[].upstream in .devhub/project.json."
        case .noProfile:
            "The project has no launch profile. Add launch.profiles with an upstream to .devhub/project.json."
        case .disabled:
            "Set network.baseURLVariable in .devhub/project.json: the app reads the mock server URL from that environment variable."
        case .noSetChosen:
            "Choose a mock set, or create one, before you turn on Mock mode."
        case .startFailed(let message):
            "The mock server did not start: \(message)"
        }
    }
}
