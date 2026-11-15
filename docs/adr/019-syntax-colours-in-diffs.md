# ADR 019. Syntax colours in diffs

Date: 2026-11-15. Status: done for Swift (see the step log).

## Context

Every diff in DevHub (request review in the tab, the details pane and the request window, unified, side by side and whole file; the changes, commits and stashes of the Git tab) showed code in one colour: green for added lines, red for removed ones, grey for context. The owner asked for the colours of Xcode: keywords, strings, comments, numbers, attributes, directives and types in their own colours, in every diff, without a third-party parser.

## Decisions

### D1. A hand-written lexer in Domain, one language at a time

- `SyntaxLexer.tokens(in:language:state:)` (Domain, `Syntax/`) lexes one line and carries a `SyntaxState` to the next line: `.code`, `.blockComment(depth:)` (Swift nests block comments) or `.multilineString(hashes:)`. The Swift scanner (`SwiftScanner`) walks the unicode scalars of the line; the token ranges are character offsets, the same unit as the emphasis and find ranges, so the view marks them the same way.
- It knows line comments (`//`, `///`), nested block comments, plain strings with escapes, interpolation `\( )` with code colours inside it (nested parentheses counted), raw strings `#"…"#` with `\#(` interpolation, multi-line strings `"""` with and without hashes, numbers (hex, binary, octal, floats, exponents, underscores), attributes `@Name`, directives and macros `#name`, backtick names, and the keyword list of `SwiftKeywords`. A capitalised identifier is a type.
- No swift-syntax, tree-sitter or regular expressions: a scanner over scalars is small, has no dependency and runs a long file in a few milliseconds. `SyntaxLanguage.language(forPath:)` picks the language by file extension; only `swift` today, and a new language is a new case with its own scanner.

### D2. Old and new side scanned apart, state reset at each hunk

`DiffSyntaxPolicy.tokens(forHunkLines:language:)` keeps two states: the old side sees the context and removed lines, the new side the context and added lines. A hunk header (`@@`) resets both, because the hunk starts in the middle of the file and the state before it is unknown. In the whole-file mode the diff has one hunk from line 1, so the colours are exact. A context line is scanned on both sides and shows the tokens of the new side.

### D3. The colours are theme tokens, the view only applies them

`Theme.syntaxKeyword`, `syntaxType`, `syntaxString`, `syntaxNumber`, `syntaxComment`, `syntaxAttribute` and `syntaxDirective` (DevHubUI) hold the only colour values, close to the Xcode light theme. `SyntaxColor` maps a kind to its token. `DiffSyntaxMapper` turns the Domain tokens into `DiffSyntaxSpan`s on the `DiffLineModel`; `DiffLine` sets the foreground colour of each span and nothing else. The backgrounds of the line (added, removed), of the changed words, of the find matches and of the current match stay as they were: colours only change the text, so no layer is broken. On a coloured line the text is primary instead of green or red, the `+` or `-` keeps the tint, and the line background is a little stronger (`DiffMapper.syntaxBackgroundOpacity`), so the change stays visible.

### D4. Computed in the mapper, with a memo for the request review

`DiffMapper.model(for:language:memo:)` lexes the hunk lines once per model, outside `body`. The request review rebuilds every file row on each change of the review state (a typed letter in a comment box, a hover), so `PullRequestDetailStore` holds a `DiffSyntaxMemo`: the tokens of the last 64 hunk-line arrays per language, keyed by the lines themselves. A rebuild then costs a hash of the lines, not a scan. The Git tab shows one expanded diff at a time and lexes without a memo. Off-main lexing was not needed: a 1,500-line Swift file scans in a few milliseconds in a Release build.

### D5. One switch in Settings

`AppSettings.diffSyntaxColors` (default on) is "Syntax colours in diffs" in Settings → General. Off: the mappers get no language and every diff looks as before. The views pass the value to the mappers (`PullRequestRowContext.syntaxColors`, `CommitRowMapper.Expansion.syntaxColors`, `FileChangeRowMapper.model(…syntaxColors:)`).

## Plan

| Step | What | State |
|---|---|---|
| 1 | Domain: `SyntaxLanguage`, `SyntaxTokenKind`, `SyntaxToken`, `SyntaxState`, `SyntaxLexer`, `SwiftScanner`, `SwiftKeywords`, `DiffSyntaxPolicy`; tests | done |
| 2 | UI: the `Theme.syntax*` tokens, `SyntaxColor`; Presentation: `DiffSyntaxSpan`, `DiffSyntaxMapper`, `DiffSyntaxMemo`, `DiffLineModel.syntax`, `DiffMapper.model(for:language:memo:)`, `DiffLine` colours, the setting and the switch; tests, headless snapshots unified and side by side | done |
| 3 | Objective-C (`.m`, `.h`), JSON, YAML scanners | later |
| 4 | Lexing off the main actor for very large whole files, when a measurement shows the need | later, maybe never |

## Consequences

- A Swift diff shows the colours of Xcode in every place a diff is drawn. Other files look as before.
- The lexer is an approximation: a type is any capitalised name, a keyword is coloured even where Swift treats it as a plain name (`get`, `set`), and a hunk that starts inside a block comment or a multi-line string is coloured as code until the comment or string ends.
- `Scripts/check-layers.sh` ignores the word `public` inside a string literal, because the keyword list holds it.

## Step log

| Commit | What it did |
|---|---|
