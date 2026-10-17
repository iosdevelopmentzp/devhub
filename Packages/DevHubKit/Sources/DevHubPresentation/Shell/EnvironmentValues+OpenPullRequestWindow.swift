import SwiftUI
import DevHubDomain
import DevHubUI

extension EnvironmentValues {
    @Entry var openPullRequestWindow: (PullRequestSummary) -> Void = { _ in }
}
