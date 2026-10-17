#if DEBUG
import Foundation
import DevHubDomain

package extension PresentationAssembly {
    func debugAddProject(path: String) {
        session.addProject(at: ProjectPath(path).url)
    }

    func debugShowTab(_ rawValue: String) {
        guard let feature = FeatureID(rawValue: rawValue) else { return }
        navigator.show(feature)
    }
}
#endif
