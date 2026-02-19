# Contributing

## Development setup

1. Install Swift 5.9+.
2. Clone the repository.
3. Run:

```bash
swift build
swift test
```

## Code quality expectations

- Keep public API source-compatible unless intentionally making a semver-major change.
- Add/adjust tests for every behavior change.
- Keep docs updated (`README.md` and DocC pages in `Sources/FractionFormatter/FractionFormatter.docc`).

## Formatting

This project uses `.swift-format` as the canonical style configuration.
If `swift-format` is available locally, run lint/format before opening a PR.

## Pull requests

- Keep PR scope focused.
- Include behavior change summary and migration notes (if needed).
- Ensure CI is green on both GitLab and GitHub.
