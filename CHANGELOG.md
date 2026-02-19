# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- DocC catalog with guides for quick start, localization/measurement integration, and troubleshooting.
- Configurable parsing and formatting policies (locale-aware parsing, reduction policy, typography controls, and negative styles).
- CI matrix expansion and release-notes artifact generation.

### Changed
- Parser hardened for cross-platform consistency and malformed input handling.
- README expanded with workaround guidance and advanced configuration examples.

## [1.0.1] - 2026-02-19

### Added
- Release tag and mirrored publication setup improvements.

### Fixed
- Invalid and edge-case fraction parsing.
- Negative number formatting and parsing correctness.
- Linux parsing inconsistencies caused by partial numeric parses.
