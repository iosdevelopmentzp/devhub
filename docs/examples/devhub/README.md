# Example `.devhub/` folder

Copy this folder into a project as `.devhub/` and adjust the values. Every field is explained in `docs/extensions.md`.

- `project.json`: how the project builds and runs, base branch, worktree rules, launch profiles, log filter, Home grid order.
- `actions/`: buttons with placements, inputs and confirmation.
- `scripts/`: executables with a `# devhub:` header; they become rows on Home without a JSON file.
- `tabs/`: a custom tab built from actions and a source script.
