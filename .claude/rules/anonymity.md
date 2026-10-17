# Anonymity rules

The repository must not name the owner's projects, company, hosts or people. `Scripts/check-anonymous.sh` checks every
file and the last commit message; `Scripts/build.sh` runs it first.

## What the check reads

- `~/.devhub/anonymity-denylist.txt`, outside the repository: one word per line, case-insensitive. A line that starts
  with `re:` is an extended regular expression. A line that starts with `#` is a comment. The file never moves into the
  repository, and its words never appear in a commit, a doc or a test.
- Built-in patterns, always on:
  - a `com.` bundle ID that is not `com.apple.` or `com.example.`;
  - a `group.com.`, `group.net.`, `group.org.`, `group.io.`, `group.app.` or `group.dev.` suite that is not
    `group.com.example`;
  - an `http://` or `https://` host that is not `github.com` (and its subdomains), `gitlab.com`, `api.anthropic.com`,
    `claude.ai`, `example.com`, `example.org` (and their subdomains), a `.invalid` host, `localhost`, `127.0.0.1`,
    `keepachangelog.com`, `semver.org` or `www.apple.com`.

## Sample vocabulary

Code, tests, previews, mocks and docs use one set of sample values:

| Thing | Value |
|---|---|
| project | `Example App` (folder `example-app`, scheme `ExampleApp`) |
| bundle ID | `com.example.app` |
| plist suite | `group.com.example.app` |
| ticket | `ABC-123` |
| branches | `main`, `feature/ABC-123-short-title` (common names such as `dev`, `develop`, `release/2.0` are fine) |
| remote | `github.com/example/app`, `gitlab.com/example/app` |
| API host | `api.example.com`, `api-qa.example.com` |
| deep link | `example://` |
| people | `alex`, `sam`, and other plain first names when a test needs more |

## Rules

- No default branch name in code as a hard value except the fallback `origin/main`.
- Every host the app talks to, other than the allowed ones above, comes from config or from the remote URL.
- A doc that came from another repository is rewritten, not copied: a decision that names a project is generalised or
  left out.
- When the check fails, rename the value to the sample vocabulary. Never add the real word to an allow list.
