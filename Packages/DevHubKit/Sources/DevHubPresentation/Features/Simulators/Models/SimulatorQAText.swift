import Foundation
import DevHubDomain

enum SimulatorQAText {
    struct Location: Equatable {
        let title: String
        let latitude: Double
        let longitude: Double
    }

    struct Language: Equatable {
        let title: String
        let code: String
        let locale: String
    }

    static let locations = [
        Location(title: "Cupertino", latitude: 37.3349, longitude: -122.0090),
        Location(title: "New York", latitude: 40.7580, longitude: -73.9855),
        Location(title: "London", latitude: 51.5074, longitude: -0.1278),
        Location(title: "Berlin", latitude: 52.5200, longitude: 13.4050),
        Location(title: "Kyiv", latitude: 50.4501, longitude: 30.5234),
        Location(title: "Tokyo", latitude: 35.6762, longitude: 139.6503),
        Location(title: "Sydney", latitude: -33.8688, longitude: 151.2093),
    ]

    static let languages = [
        Language(title: "English (US)", code: "en", locale: "en_US"),
        Language(title: "English (UK)", code: "en-GB", locale: "en_GB"),
        Language(title: "German", code: "de", locale: "de_DE"),
        Language(title: "French", code: "fr", locale: "fr_FR"),
        Language(title: "Spanish", code: "es", locale: "es_ES"),
        Language(title: "Ukrainian", code: "uk", locale: "uk_UA"),
        Language(title: "Japanese", code: "ja", locale: "ja_JP"),
        Language(title: "Arabic (right to left)", code: "ar", locale: "ar_SA"),
    ]

    static func title(for size: SimulatorTextSize) -> String {
        switch size {
        case .extraSmall: "Extra small"
        case .small: "Small"
        case .medium: "Medium"
        case .large: "Large (default)"
        case .extraLarge: "Extra large"
        case .extraExtraLarge: "Extra extra large"
        case .extraExtraExtraLarge: "Largest"
        case .accessibilityMedium: "Accessibility M"
        case .accessibilityLarge: "Accessibility L"
        case .accessibilityExtraLarge: "Accessibility XL"
        case .accessibilityExtraExtraLarge: "Accessibility XXL"
        case .accessibilityExtraExtraExtraLarge: "Accessibility XXXL"
        }
    }

    static func title(for service: PrivacyService) -> String {
        switch service {
        case .all: "All services"
        case .microphone: "Microphone"
        case .photos: "Photos"
        case .photosAdd: "Add photos only"
        case .location: "Location when in use"
        case .locationAlways: "Location always"
        case .contacts: "Contacts"
        case .calendar: "Calendar"
        case .reminders: "Reminders"
        case .motion: "Motion"
        case .mediaLibrary: "Media library"
        }
    }

    static func logTitle(for setting: SimulatorSetting, simulator: String) -> String {
        switch setting {
        case .appearance(let appearance): "\(appearance == .dark ? "Dark" : "Light") appearance on \(simulator)"
        case .textSize(let size): "Text size \(title(for: size)) on \(simulator)"
        case .cleanStatusBar: "Clean status bar (9:41) on \(simulator)"
        case .resetStatusBar: "Real status bar on \(simulator)"
        case let .location(latitude, longitude): "Location \(latitude), \(longitude) on \(simulator)"
        case .clearLocation: "Location cleared on \(simulator)"
        case let .language(code, locale): "Language \(code), region \(locale) on \(simulator)"
        case let .privacy(change, service, bundleID): "\(change.rawValue.capitalized) \(title(for: service)) for \(bundleID.isEmpty ? "every app" : bundleID) on \(simulator)"
        }
    }

    static func screenshotName(simulator: String, date: Date) -> String {
        fileStem(simulator: simulator, date: date) + ".png"
    }

    static func recordingName(simulator: String, date: Date) -> String {
        fileStem(simulator: simulator, date: date) + ".mov"
    }

    private static func fileStem(simulator: String, date: Date) -> String {
        let stamp = date.formatted(.iso8601.year().month().day().dateSeparator(.dash).time(includingFractionalSeconds: false).timeSeparator(.omitted))
        let name = simulator.replacingOccurrences(of: "/", with: "-")
        return "\(name) \(stamp.replacingOccurrences(of: "T", with: " ").replacingOccurrences(of: "Z", with: ""))"
    }
}
