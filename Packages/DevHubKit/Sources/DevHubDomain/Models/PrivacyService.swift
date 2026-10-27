import Foundation

package enum PrivacyService: String, CaseIterable, Hashable, Sendable {
    case all
    case microphone
    case photos
    case photosAdd = "photos-add"
    case location
    case locationAlways = "location-always"
    case contacts
    case calendar
    case reminders
    case motion
    case mediaLibrary = "media-library"
}
