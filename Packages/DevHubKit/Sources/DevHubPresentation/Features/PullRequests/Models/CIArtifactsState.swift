import Foundation
import DevHubDomain

enum CIArtifactsState: Equatable {
    case loading
    case loaded([CIArtifact])
    case failure(String)
}
