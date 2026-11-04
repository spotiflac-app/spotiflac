# SpotiFLAC ownership status

Updated 2026-11-05.
Website: https://spotiflac.com
Repository: https://github.com/spotiflac-app/spotiflac

## Implemented

- Project-owned namespace `com.spotiflac.app`, including native/JNI channels,
  bundle identifiers, app groups, Android package directories, Linux packaging,
  installer metadata and tests.
- Publisher metadata identifies SpotiFLAC; original copyright and contributor
  notices remain where required. The Windows installer has a fresh product GUID.
- First independent version `1.0.0+1` with dated change notices.
- Mobile and desktop updates use the project repository. One release job owns
  the tag, release notes, all successful platform assets, and checksum manifest.
- Releases start as drafts. Telegram notifications and cross-repository release
  tokens are removed. Missing signing secrets cause failure, not unsigned Android
  publication. Windows/macOS signing remains optional and accurately described.
- Announcements use this repository's `config/app.json`. Funding is disabled;
  inherited donation accounts, wallet and sponsor button have been removed.
  The announcement cache is separate from the inherited configuration cache.
- Inherited community/status/API links are removed from About. Unconfigured
  Discord and the optional original-operator lyrics backup are disabled.
  Mobile workflows do not require the inherited encrypted Discord SDK.
- The website is linked in README, About, package and installer metadata.
  Inherited featured/ranking badges are removed.
- The iOS source feed is empty until a real public build is available. A helper
  fills it using the actual IPA's identity, version, file size and URL.
- A new encrypted Android release-signing key is generated privately outside
  the source tree and excluded by Git ignore rules. No key is embedded here.

## Verified builds and checks

- Flutter formatting and analysis passed; 3,557 Flutter tests passed and 12 were
  skipped by the existing suite.
- Rust formatting, Clippy and workspace tests passed: 475 tests passed, with
  7 ignored by the existing suite.
- Android debug compilation, native unit tests, both release APK architectures,
  payload audits, package signatures and symbol provenance passed.
- iOS device and universal simulator XCFrameworks compiled. The unsigned iOS
  release application built and passed its payload audit.
- Desktop application builds and package audits passed for Windows x64/ARM64,
  Linux x64/ARM64 and universal macOS. Windows CI failures now fail the workflow
  instead of being treated as informational failures.
- All 23 local packaging and release-integrity tests passed.
- The local repository root and Git metadata are owned by the Windows user;
  ordinary Git commands work without a safe-directory override.

Evidence: [Android, Flutter and Rust checks](https://github.com/spotiflac-app/spotiflac/actions/runs/41910773816),
[iOS retry on the Intel runner](https://github.com/spotiflac-app/spotiflac/actions/runs/41913691452),
[desktop builds](https://github.com/spotiflac-app/spotiflac/actions/runs/41916044799).
The first run's iOS job was cancelled by GitHub because no ARM Mac runner was
available; the separate Intel-runner job above verifies that platform.

## Distribution still to complete

- No production release has been published. Run the Release workflow for the
  first draft, validate fresh installation, playback, downloads and an upgrade,
  then decide when to publish. Android CI uses a test key; production releases
  use the four configured project-owned signing secrets.
- Apple/Windows trusted distribution signing remains optional and requires
  project-owned certificates/accounts. The iOS CI build is unsigned; desktop
  CI artifacts are test builds, not a claim of store distribution or notarization.
- The repository remains private by owner choice. Public app update checks,
  raw configuration and website downloads cannot read private GitHub assets.
  Do not embed a GitHub token in the app. Choose a public distribution endpoint
  when the project is ready for public downloads.
- Website development is deferred by the owner. Existing website download links
  remain in place until spotiflac.com is ready; this work did not change the site.
- Optional Discord, OAuth, translation, funding and community integrations stay
  disabled or unconfigured until project-owned accounts are supplied.

## Licensing

This is an independently maintained derivative. Brand and repository control
does not transfer copyright in inherited code. LICENSE, COPYING, NOTICE and
third-party notices remain. Dated modifications are recorded. Distribute source
and notices as required by the existing license when distributing binaries.

See [Release setup](RELEASE_SETUP.md) for operational instructions.
