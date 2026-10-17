import Foundation

enum SimctlListFixture {
    static let json = Data("""
    {
      "devices": {
        "com.apple.CoreSimulator.SimRuntime.iOS-17-5": [
          { "udid": "A1", "name": "iPhone 15", "state": "Shutdown", "deviceTypeIdentifier": "com.apple.CoreSimulator.SimDeviceType.iPhone-15", "isAvailable": true }
        ],
        "com.apple.CoreSimulator.SimRuntime.iOS-18-2": [
          { "udid": "B1", "name": "iPad Air", "state": "Booted", "deviceTypeIdentifier": "com.apple.CoreSimulator.SimDeviceType.iPad-Air-11-inch-M2", "isAvailable": true },
          { "udid": "B2", "name": "iPhone 16 Pro", "state": "Booting", "deviceTypeIdentifier": "com.apple.CoreSimulator.SimDeviceType.iPhone-16-Pro", "isAvailable": true },
          { "udid": "B3", "name": "iPhone 16", "state": "Shutting Down", "deviceTypeIdentifier": "com.apple.CoreSimulator.SimDeviceType.iPhone-16" },
          { "udid": "B4", "name": "iPhone 10", "state": "Creating", "deviceTypeIdentifier": "com.apple.CoreSimulator.SimDeviceType.iPhone-X" },
          { "udid": "B5", "name": "iPhone Old", "state": "Shutdown", "isAvailable": false },
          { "udid": "B6", "name": "iPad mini", "state": "Shutdown" }
        ],
        "com.apple.CoreSimulator.SimRuntime.iOS-26-0": [
          { "udid": "C1", "name": " iPhone 17 ", "state": "Shutdown", "deviceTypeIdentifier": "com.apple.CoreSimulator.SimDeviceType.iPhone-17" }
        ],
        "com.apple.CoreSimulator.SimRuntime.watchOS-11-0": [
          { "udid": "W1", "name": "Apple Watch", "state": "Shutdown", "isAvailable": true }
        ],
        "com.apple.CoreSimulator.SimRuntime.iOS-16-4": [
          { "udid": "D1", "name": "iPhone 14", "state": "Shutdown", "isAvailable": false }
        ]
      }
    }
    """.utf8)

    static let malformed = Data("{\"runtimes\": []}".utf8)
}
