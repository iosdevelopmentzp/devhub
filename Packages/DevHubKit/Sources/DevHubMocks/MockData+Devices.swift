import Foundation
import DevHubDomain

extension MockData {
    package static let devices: [Simulator] = [
        Simulator(id: "device-sam", name: "Sam's iPhone", kind: .phone, state: .booted, isFavorite: false, isPhysical: true, runtime: "iOS 26.1"),
        Simulator(id: "device-alex", name: "Alex's iPad", kind: .pad, state: .shutdown, isFavorite: false, isPhysical: true, runtime: "iPadOS 18.6")
    ]
}
