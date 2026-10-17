import Foundation

package extension Date {

    var relativeDescription: String {
        formatted(.relative(presentation: .named, unitsStyle: .abbreviated))
    }
}
