# Release Checklist

1. Confirm branch is clean and tests pass locally.
2. Update `CHANGELOG.md` from `Unreleased` entries.
3. Verify API compatibility and semver bump level.
4. Run full CI (GitLab and GitHub).
5. Create annotated tag (`git tag -a X.Y.Z -m "Release X.Y.Z"`).
6. Push branch and tag to GitLab and GitHub.
7. Verify Swift Package Index sees the new tag.
8. Verify generated release notes artifact in CI for the tag pipeline.
9. Post-release smoke test on fresh clone (`swift build`, `swift test`).
