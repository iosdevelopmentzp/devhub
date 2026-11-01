import Foundation

enum DiskCleanupFixture {
    static let runtimeList = """
    {
      "4B1E1916-0D85-4542-9D9D-DC46F18796C9" : {
        "build" : "23E244",
        "deletable" : true,
        "identifier" : "4B1E1916-0D85-4542-9D9D-DC46F18796C9",
        "kind" : "Patchable Cryptex Disk Image",
        "lastUsedAt" : "2026-04-17T12:10:38Z",
        "platformIdentifier" : "com.apple.platform.iphonesimulator",
        "runtimeIdentifier" : "com.apple.CoreSimulator.SimRuntime.iOS-26-4",
        "sizeBytes" : 8485747282,
        "state" : "Ready",
        "version" : "26.4"
      },
      "6D0773D6-2D57-4372-A123-EFEA59A98D03" : {
        "build" : "22G86",
        "deletable" : true,
        "identifier" : "6D0773D6-2D57-4372-A123-EFEA59A98D03",
        "platformIdentifier" : "com.apple.platform.iphonesimulator",
        "sizeBytes" : 8838255185,
        "version" : "18.6"
      },
      "A1B2C3D4-0000-0000-0000-000000000000" : {
        "build" : "23R100",
        "deletable" : true,
        "identifier" : "A1B2C3D4-0000-0000-0000-000000000000",
        "platformIdentifier" : "com.apple.platform.watchsimulator",
        "version" : "26.0"
      },
      "FFFF0000-0000-0000-0000-000000000000" : {
        "build" : "21A100",
        "deletable" : false,
        "identifier" : "FFFF0000-0000-0000-0000-000000000000",
        "platformIdentifier" : "com.apple.platform.iphonesimulator",
        "sizeBytes" : 100,
        "version" : "17.0"
      }
    }
    """

    static let unavailableDevices = """
    {
      "devices" : {
        "com.apple.CoreSimulator.SimRuntime.iOS-17-0" : [
          {
            "dataPath" : "/Users/alex/Library/Developer/CoreSimulator/Devices/AAAA/data",
            "dataPathSize" : 1000,
            "udid" : "AAAA",
            "isAvailable" : false,
            "availabilityError" : "runtime profile not found",
            "name" : "iPhone 15"
          },
          {
            "dataPath" : "/Users/alex/Library/Developer/CoreSimulator/Devices/BBBB/data",
            "dataPathSize" : 500,
            "udid" : "BBBB",
            "isAvailable" : false,
            "name" : "iPad Air"
          }
        ],
        "com.apple.CoreSimulator.SimRuntime.iOS-26-4" : [

        ]
      }
    }
    """

    static let noUnavailableDevices = """
    {
      "devices" : {
        "com.apple.CoreSimulator.SimRuntime.iOS-26-4" : [

        ]
      }
    }
    """
}
