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
- Official mobile and desktop release builds use the separate project-owned
  downloads repository for updates. One release job owns
  the tag, release notes, all successful platform assets, and checksum manifest.
- Releases start as drafts. Telegram notifications and cross-repository release
  tokens are removed. Missing signing secrets cause failure, not unsigned Android
  publication. Windows/macOS signing remains optional and accurately described.
- Official release announcements use the downloads repository's `config/app.json`. Funding is disabled;
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
- All 29 local packaging, configuration and release-integrity tests passed.
- The local repository root and Git metadata are owned by the Windows user;
  ordinary Git commands work without a safe-directory override.

Evidence: [Android, Flutter and Rust checks](https://github.com/spotiflac-app/spotiflac/actions/runs/41910773816),
[iOS retry on the Intel runner](https://github.com/spotiflac-app/spotiflac/actions/runs/41913691452),
[desktop builds](https://github.com/spotiflac-app/spotiflac/actions/runs/41916044799).
The first run's iOS job was cancelled by GitHub because no ARM Mac runner was
available; the separate Intel-runner job above verifies that platform.

## Release staging and Windows installation

- All seven platform build jobs in [the release run](https://github.com/spotiflac-app/spotiflac/actions/runs/41927209307) passed for source commit `29f18d482341d697817db086043223693b49ae67`.
- GitHub prevented the final assembly job from starting because account payments or the Actions spending limit require attention. This was an account billing restriction, not a compilation failure. The successful artifacts were downloaded, checked against GitHub's SHA-256 digests, verified against their package manifests and assembled locally.
- The private source draft and [separate downloads draft](https://github.com/spotiflac-app/spotiflac-releases/releases/tag/untagged-8c718fd1f80ab157cfb4) contain the verified packages. The downloads draft additionally includes matching source, license notices and an iOS feed generated from the actual IPA. Its 17 uploaded assets were verified against their local SHA-256 digests. Nothing is published.
- Android production APKs use the configured project-owned signing key. The iOS IPA is unsigned, macOS is ad-hoc signed, and Windows is unsigned pending trusted signing credentials.
- On Windows x64, the per-user release installer succeeded. Reinstalling the same version preserved settings byte for byte. The installed release reopened without repeating onboarding, imported the synthetic two-second WAV and advanced its playback state. The installed binary contains the public downloads/configuration addresses.
- These checks do not establish physical Android/iPhone compatibility, acoustic output quality, a version-number upgrade, or provider search/download functionality. No download extension was installed during the Windows smoke test.
- Both Windows release architectures passed. Future Windows release failures now fail the workflow rather than being ignored.

## Remaining external work

- Complete provider search/download and version-upgrade tests, plus physical Android/iPhone installation and playback tests. No authorized phone was connected; an emulator test is not being claimed. Linux, macOS and Windows ARM64 have build/audit results, but native installation and playback were not exercised on this Windows x64 host.
- Trusted Apple distribution/notarization and Windows signing require owner-held certificates or verified service accounts. Available Apple Developer and SignPath pages required sign-in, and no usable certificates were supplied. Self-signed certificates do not establish public distribution trust.
- Restore GitHub Actions availability through the account's Billing and plans settings. No payment or spending-limit change was made.
- Publish the downloads draft after the remaining validation. Until then, its release/update asset URLs are unavailable to anonymous users. The development repository remains private, and no GitHub token is embedded in the app.
- Website development remains deferred by the owner. Existing website download links are unchanged until spotiflac.com is ready.
- Optional Discord, OAuth, translation, funding and community integrations remain disabled or unconfigured until project-owned accounts are supplied.

## Licensing

This is an independently maintained derivative. Brand and repository control
does not transfer copyright in inherited code. LICENSE, COPYING, NOTICE and
third-party notices remain. Dated modifications are recorded. Distribute source
and notices as required by the existing license when distributing binaries.

See [Release setup](RELEASE_SETUP.md) for operational instructions.
