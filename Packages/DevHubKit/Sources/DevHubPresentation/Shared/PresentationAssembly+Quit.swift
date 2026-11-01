import Foundation

extension PresentationAssembly {
    package func prepareForQuit() {
        simulatorQA.stopAllRecordings()
    }
}
