import SwiftUI
import DevHubDomain
import DevHubUI

extension EnvironmentValues {
    @Entry var openMergeRequestWindow: (MergeRequestSummary) -> Void = { _ in }
}
