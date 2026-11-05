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
- Product version `5.2.6+165`, restored from the downloaded source snapshot. Version numbering continues from that baseline.
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
- All 33 local packaging, configuration, version and release-integrity tests passed.
- The local repository root and Git metadata are owned by the Windows user;
  ordinary Git commands work without a safe-directory override.

Evidence: [Android, Flutter and Rust checks](https://github.com/spotiflac-app/spotiflac/actions/runs/41910773816),
[iOS retry on the Intel runner](https://github.com/spotiflac-app/spotiflac/actions/runs/41913691452),
[desktop builds](https://github.com/spotiflac-app/spotiflac/actions/runs/41916044799).
The first run's iOS job was cancelled by GitHub because no ARM Mac runner was
available; the separate Intel-runner job above verifies that platform.

## Version correction and validation

- The target release is `v5.2.6`, build `165`. These are the exact numbers in the downloaded source snapshot. The version counter is not being reset.
- Previous validation binaries embed an incorrect initial version. They remain historical test evidence and must not be renamed or published as 5.2.6. Their unpublished drafts are retired under a QA tag. All platforms require fresh builds from the corrected source.
- All seven platform jobs in [the earlier build run](https://github.com/spotiflac-app/spotiflac/actions/runs/41927209307) passed. The final assembly runner was blocked by GitHub account billing or its Actions limit. Local assembly and both draft uploads were verified before retirement. Nothing was published.
- Windows x64 installation and same-version reinstall settings persistence were checked against that earlier binary. Local synthetic-track import and playback state worked. Those results are not a version-number upgrade test or validation of a new 5.2.6 binary.
- The shipped Windows x64 backend and the Linux x64 backend extracted from the verified Debian package passed isolated provider tests: HTTP catalog search, FLAC download, exact byte matching, full audio decoding and rejection of an ungranted output directory. Only synthetic audio on loopback was used. No installed app settings or music accounts were used.
- `scripts/smoke_test_desktop_provider.py` makes those checks reproducible. Future Desktop and Release workflows run them on Windows x64 and Linux x64 and save JSON reports. The updated hosted checks still require GitHub Actions availability; the local executions passed.
- Linux backend execution was checked in Ubuntu 26.04 under WSL. Its full desktop UI was not launched; the extracted package's declared desktop dependencies are not all installed in that environment. macOS and ARM64 runtime checks remain outstanding.
- Android validation APKs used the configured project signing key. The earlier iOS IPA is unsigned, macOS is ad-hoc signed and Windows is unsigned. Future corrected builds retain these signing prerequisites.

Corrected-version build attempt: [5.2.6 build](https://github.com/spotiflac-app/spotiflac/actions/runs/41964910209). GitHub refused to start even the version-preflight job because recent account payments failed or the Actions spending limit needs attention. No platform compiler ran. This is an account restriction, not a compile error. After account access is restored, rerun this workflow or dispatch Release with version `v5.2.6`; never relabel the retired validation binaries.

## Remaining external work

- Build the corrected 5.2.6+165 source, then complete commercial-provider/GUI download and version-upgrade tests, plus physical Android/iPhone installation and playback tests. No authorized phone was connected; an emulator test is not being claimed. Linux, macOS and Windows ARM64 have build/audit results, but native installation and playback were not exercised on this Windows x64 host.
- Trusted Apple distribution/notarization and Windows signing require owner-held certificates or verified service accounts. Available Apple Developer and SignPath pages required sign-in, and no usable certificates were supplied. Self-signed certificates do not establish public distribution trust.
- Restore GitHub Actions availability through the account's Billing and plans settings. No payment or spending-limit change was made.
- Stage and publish a corrected-version downloads draft after the remaining validation. The retired QA drafts must stay unpublished; public download/update assets are not available yet. The development repository remains private, and no GitHub token is embedded in the app.
- Website development remains deferred by the owner. Existing website download links are unchanged until spotiflac.com is ready.
- Optional Discord, OAuth, translation, funding and community integrations remain disabled or unconfigured until project-owned accounts are supplied.

## Licensing

This is an independently maintained derivative. Brand and repository control
does not transfer copyright in inherited code. LICENSE, COPYING, NOTICE and
third-party notices remain. Dated modifications are recorded. Distribute source
and notices as required by the existing license when distributing binaries.

See [Release setup](RELEASE_SETUP.md) for operational instructions.
