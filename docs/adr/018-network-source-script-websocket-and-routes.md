# ADR 018. Network source script, WebSocket pass-through and upstream routes

Date: 2026-11-08. Status: done (2026-11-08). The live check on the owner's app is still open.

## Context

The owner compared this app with the main DevHub, which was built for one app, and asked to close the gaps that the `.devhub` config could not cover, without making the tool much more complex, and to describe everything in the docs (2026-11-08). The comparison found:

1. **The Network tab saw only the mock server.** The main DevHub read the session log file of its app and listed every request, also from a launch in Xcode and without a mock server. This app dropped that reader on purpose (STATUS decision 8): the log format belongs to one app.
2. **WebSocket upgrades got status 501.** An app that builds its socket URL from the same base URL as its REST calls (Socket.IO does this when the base URL is replaced) lost its socket as soon as it ran through the mock server. The owner called this a big problem.
3. **One upstream per profile.** The owner's app sends REST calls and its Socket.IO connection to two different real hosts, but both get the one base URL of the mock server. The server cannot tell the original host.
4. Smaller gaps, closed by docs and config only: the first launch profile is the default (not documented), deep link and push presets (script actions), Bitrise (not supported; a chat command covers the owner's need), a `when` condition on an input value (already listed in `docs/customization.md`).

## Decisions

1. **`network.sourceScript`.** A project script reports requests; DevHub never parses a log format in Swift. The script prints one `@devhub {"request": {...}}` line per request (fields: `method` and `url`, optional `id`, `status`, `statusText`, `startedAt`, `durationMs`, headers, bodies, `error`). A later line with the same `id` replaces the row. `@devhub {"error": "…"}` shows a bar over the list and the stream goes on. A non-zero exit shows the last plain line.
   - Port `NetworkSourceRepository.follow(_ ScriptRunRequest)`; `ScriptNetworkSourceRepository` runs the script through `ShellScriptRunner` without a time limit, parses lines with `NetworkSourceLineParser` (the DTO is private there) and redacts with `NetworkRequestRedactor` and `LogRedactor`. Ids start at `1 << 40`, away from the mock server ids (`1 << 32`).
   - `FollowNetworkSourceUseCase` finds the script with the path rules of the status script (`SimulatorStatusPolicy.candidates`) and maps the exit code.
   - `NetworkStore` runs it from `.task(id: sourceKey)` of the Network view: the key holds the simulator, the script, the project and a restart counter, so a change or Retry restarts it and a closed tab stops it. The script replays the recent requests on every start.
   - The environment is the one of a simulator row action, built by the new `SimulatorScriptEnvironment`, which `SimulatorStatusStore` now uses too.
   - `NetworkTrafficPolicy.merge` sorts the mock server rows and the script rows by start time. While the mock server runs for the simulator, script rows for `127.0.0.1` and `localhost` are hidden: the app log of a redirected app names the mock server, and the server lists those requests itself.
   - `NetworkRequest.origin` (`mockServer`, `sourceScript`) gives the `script` tag and the detail note.
2. **WebSocket pass-through, not mocking.** `LocalMockServer` hands an upgrade request to `WebSocketTunnel`: a TCP connection to the upstream (TLS for `https`), the same handshake with the upstream `Host` and `Origin` (`WebSocketHandshake`), then bytes in both directions until one side closes. `Sec-WebSocket-Extensions` is dropped, so no side compresses and `WebSocketFrameReader` can read the frames. `WebSocketTranscript` keeps the last 500 messages (`→` sent, `←` received) in the response body of the one row of the connection, updated at most every 0.3 s; the duration is the time the connection was open. An unreachable upstream answers 502. Mock rules do not apply to a WebSocket. `MockServerStore.receive` now replaces a row with the same id, through `NetworkTrafficPolicy.upsert`.
3. **`launch.profiles[].routes`.** `[{"path": "/socket.io/", "upstream": "https://…"}]`: the longest route whose path starts the request path picks the upstream, for HTTP and WebSocket. `MockUpstream` (the base URL and its routes) replaces the plain URL in `MockServerRepository`; `MockUpstreamPolicy.upstream(for:)` validates the routes (`MockServerError.badRoute`). A restored server takes the routes of the profile that owns its saved upstream host.
4. **No new tool, host or dependency.** The script is the user's own code. The tunnel connects only to the upstream of the profile, which the HTTP forwarding already used.

## Not done, on purpose

- Mocking WebSocket messages. It needs a message rule format and a per-protocol view (Socket.IO packets); pass-through fixes the broken socket, which was the problem.
- A Bitrise integration. CI stays CircleCI; the owner's Bitrise need is a chat command.
- A `when` condition on a tab input value. No action of the owner needs it today.

## Plan and step log

| Step | What | State |
|---|---|---|
| 1 | Domain: `MockUpstream`, `MockRoute`, `ProfileRoute`, `NetworkConfig.sourceScript`, `NetworkRequest.origin`, the port, the use case, `NetworkTrafficPolicy` | done |
| 2 | Data: `NetworkSourceLineParser`, `ScriptNetworkSourceRepository`, the WebSocket tunnel, routes in `MockExchangeHandler` | done |
| 3 | Presentation: `NetworkStore` source following, notice bar, empty state, tags and notes | done |
| 4 | Docs: extensions §5 and §10, the Network page, customization, the example script, STATUS, the owner's project config | done |
| 5 | Live check: the owner's app on a simulator with Passthrough (REST and Socket.IO through the route) and with the source script after a launch from Xcode | open |

| Commit | What |
|---|---|
| `c5f382b` | Steps 1 to 4: `network.sourceScript`, WebSocket pass-through with a message transcript, `launch.profiles[].routes`, the docs and the example script. |
