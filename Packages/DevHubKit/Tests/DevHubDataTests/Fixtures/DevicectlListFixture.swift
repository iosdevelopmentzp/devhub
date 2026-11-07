import Foundation

enum DevicectlListFixture {
    static let json = Data("""
    {
      "info": { "commandType": "devicectl.list.devices", "outcome": "success", "jsonVersion": 3 },
      "result": {
        "devices": [
          {
            "identifier": "11111111-2222-3333-4444-555555555555",
            "connectionProperties": { "pairingState": "paired", "tunnelState": "unavailable", "transportType": "wired" },
            "deviceProperties": { "name": "Alex's iPhone", "osVersionNumber": "18.6.2", "developerModeStatus": "enabled" },
            "hardwareProperties": { "platform": "iOS", "deviceType": "iPhone", "udid": "00008110-000000000000001A", "reality": "physical", "marketingName": "iPhone 13" }
          },
          {
            "identifier": "66666666-7777-8888-9999-000000000000",
            "connectionProperties": { "pairingState": "paired", "tunnelState": "connected", "transportType": "localNetwork" },
            "deviceProperties": { "name": " Sam's iPhone ", "osVersionNumber": "27.0.1", "developerModeStatus": "enabled" },
            "hardwareProperties": { "platform": "iOS", "deviceType": "iPhone", "udid": "00008110-000000000000001B", "reality": "physical", "marketingName": "iPhone 13 Pro Max" }
          },
          {
            "identifier": "aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee",
            "connectionProperties": { "pairingState": "paired", "tunnelState": "connected" },
            "deviceProperties": { "name": "", "osVersionNumber": "18.6" },
            "hardwareProperties": { "platform": "iOS", "deviceType": "iPad", "udid": "00008110-000000000000001C", "reality": "physical", "marketingName": "iPad Air" }
          },
          {
            "identifier": "ffffffff-1111-2222-3333-444444444444",
            "connectionProperties": { "pairingState": "paired", "tunnelState": "unavailable" },
            "deviceProperties": { "name": "Sam's Watch", "osVersionNumber": "11.6" },
            "hardwareProperties": { "platform": "watchOS", "deviceType": "appleWatch", "udid": "00008301-000000000000001D", "reality": "physical" }
          },
          {
            "identifier": "12121212-3434-5656-7878-909090909090",
            "connectionProperties": { "tunnelState": "connected" },
            "deviceProperties": { "name": "iPhone 17 Pro", "osVersionNumber": "26.0" },
            "hardwareProperties": { "platform": "iOS", "deviceType": "iPhone", "udid": "SIM-1", "reality": "virtual" }
          },
          {
            "identifier": "no-hardware"
          }
        ]
      }
    }
    """.utf8)

    static let launch = Data("""
    {
      "info": { "outcome": "success" },
      "result": {
        "deviceIdentifier": "66666666-7777-8888-9999-000000000000",
        "process": { "executable": "file:///private/var/containers/Bundle/Application/X/App.app/App", "processIdentifier": 23581 }
      }
    }
    """.utf8)

    static let apps = Data("""
    {
      "info": { "outcome": "success" },
      "result": {
        "apps": [
          { "bundleIdentifier": "com.example.app", "name": "Example App", "version": "1.5.2", "bundleVersion": "1", "builtByDeveloper": true },
          { "bundleIdentifier": "com.example.other", "name": "Other" }
        ]
      }
    }
    """.utf8)

    static let malformed = Data("{\"info\": {}}".utf8)
}
