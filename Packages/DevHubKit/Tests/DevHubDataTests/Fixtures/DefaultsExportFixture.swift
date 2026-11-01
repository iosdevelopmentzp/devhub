import Foundation

enum DefaultsExportFixture {
    static let appSuite = """
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    <plist version="1.0">
    <dict>
        <key>onboardingDone</key>
        <true/>
        <key>apiEnvironment</key>
        <string>staging</string>
        <key>launchCount</key>
        <integer>14</integer>
        <key>volume</key>
        <real>0.5</real>
        <key>lastSyncDate</key>
        <date>2026-10-30T09:41:00Z</date>
        <key>token</key>
        <data>AAECAw==</data>
        <key>recentSearches</key>
        <array>
            <string>shoes</string>
            <integer>2</integer>
        </array>
        <key>featureFlags</key>
        <dict>
            <key>search</key>
            <false/>
            <key>checkout</key>
            <true/>
        </dict>
    </dict>
    </plist>
    """

    static let empty = """
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    <plist version="1.0">
    <dict/>
    </plist>
    """

    static let groups = """
    group.com.example.app\t/Users/alex/Library/Developer/CoreSimulator/Devices/U1/data/Containers/Shared/AppGroup/G1
    group.com.example.app.widgets\t/Users/alex/Library/Developer/CoreSimulator/Devices/U1/data/Containers/Shared/AppGroup/G 2

    """
}
