import Foundation

enum ClaudeUsageFixture {
    static let json = Data("""
    {
      "seven_day_opus": { "utilization": 5.5, "resets_at": "2026-01-08T00:00:00Z" },
      "seven_day": { "utilization": 10, "resets_at": null },
      "five_hour": { "utilization": 42.0, "resets_at": "2026-01-02T03:04:05.000+00:00" },
      "seven_day_oauth_apps": { "utilization": 1 },
      "seven_day_claude_code": { "utilization": 3 },
      "seven_day_sonnet": null,
      "extra_usage": { "utilization": 99 }
    }
    """.utf8)

    static let scoped = Data("""
    {
      "five_hour": { "utilization": 18.0, "resets_at": null },
      "seven_day": { "utilization": 9.0, "resets_at": null },
      "seven_day_opus": { "utilization": 5.5, "resets_at": null },
      "limits": [
        { "kind": "session", "percent": 18, "resets_at": null, "scope": null },
        { "kind": "weekly_all", "percent": 9, "resets_at": null, "scope": null },
        { "kind": "weekly_scoped", "percent": 7, "resets_at": "2026-01-08T00:00:00Z", "scope": { "model": { "id": null, "display_name": "Fable" }, "surface": null } },
        { "kind": "weekly_scoped", "percent": 6, "resets_at": null, "scope": { "model": { "display_name": "Opus" } } },
        { "kind": "weekly_scoped", "percent": 3, "resets_at": null, "scope": { "model": null, "surface": { "display_name": "Claude Code" } } },
        { "kind": "weekly_scoped", "percent": 1, "resets_at": null, "scope": null }
      ]
    }
    """.utf8)

    static let noLimits = Data("{\"five_hour\": null, \"seven_day_oauth_apps\": {\"utilization\": 1}}".utf8)

    static let notAnObject = Data("[]".utf8)

    static let credentials = Data("""
    {"claudeAiOauth":{"accessToken":"sk-ant-oat-fake","refreshToken":"sk-ant-ort-fake","expiresAt":1767323045000,"subscriptionType":"max"}}
    """.utf8)

    static let credentialsWithoutExtras = Data("""
    {"claudeAiOauth":{"accessToken":"sk-ant-oat-fake"}}
    """.utf8)

    static let credentialsWithEmptyToken = Data("""
    {"claudeAiOauth":{"accessToken":"","expiresAt":1767323045000}}
    """.utf8)

    static let credentialsWithoutOAuth = Data("{\"other\":{}}".utf8)
}
