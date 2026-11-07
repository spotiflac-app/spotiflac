# SpotiFLAC ownership status

Updated 2026-11-06.
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
- Previous validation binaries embed an incorrect initial version. They remain historical test evidence and must not be renamed or published as 5.2.6. Their unpublished drafts are retired under a QA tag. Fresh corrected-version Windows x64 and Android builds are documented below; the other platforms still require rebuilding.
- All seven platform jobs in [the earlier build run](https://github.com/spotiflac-app/spotiflac/actions/runs/41927209307) passed. The final assembly runner was blocked by GitHub account billing or its Actions limit. Local assembly and both draft uploads were verified before retirement. Nothing was published.
- Windows x64 installation and same-version reinstall settings persistence were checked against that earlier binary. Local synthetic-track import and playback state worked. Those results are not a version-number upgrade test or validation of a new 5.2.6 binary.
- The shipped Windows x64 backend and the Linux x64 backend extracted from the verified Debian package passed isolated provider tests: HTTP catalog search, FLAC download, exact byte matching, full audio decoding and rejection of an ungranted output directory. Only synthetic audio on loopback was used. No installed app settings or music accounts were used.
- `scripts/smoke_test_desktop_provider.py` makes those checks reproducible. Future Desktop and Release workflows run them on Windows x64 and Linux x64 and save JSON reports. The updated hosted checks still require GitHub Actions availability; the local executions passed.
- Linux backend execution was checked in Ubuntu 26.04 under WSL. Its full desktop UI was not launched; the extracted package's declared desktop dependencies are not all installed in that environment. macOS and ARM64 runtime checks remain outstanding.
- Android validation APKs used the configured project signing key. The earlier iOS IPA is unsigned, macOS is ad-hoc signed and Windows is unsigned. Future corrected builds retain these signing prerequisites.

Corrected-version build attempt: [5.2.6 build](https://github.com/spotiflac-app/spotiflac/actions/runs/41964910209). GitHub refused to start even the version-preflight job because recent account payments failed or the Actions spending limit needs attention. No platform compiler ran. This is an account restriction, not a compile error. After account access is restored, rerun this workflow or dispatch Release with version `v5.2.6`; never relabel the retired validation binaries.

## Local Windows 5.2.6+165 build

The corrected Windows x64 app was successfully compiled locally from commit `7364d30e62b1d06987a468b7cd4e1f09164abf60`. Installer, portable ZIP, matching source archive and SHA-256 checksums were generated. All 62 native binaries and the AOT snapshot passed their audit. Synthetic provider search/download, full audio decoding and output-directory protection passed against the finished bundle.

The installer upgraded the earlier local QA installation to 5.2.6+165 and preserved its preferences byte for byte before launch. The updated app started with its prior queue intact. The packages remain unsigned and unpublished. This is Windows x64 coverage; it does not establish physical phone behavior, other-platform compatibility or commercial-provider/GUI downloads.

The unchanged core Rust backend and LGPL audio tools were reused from checksum-verified validation components after source-tree equality checks. The Windows media-control plugin was compiled locally. Initial setup required Flutter 3.47.7, Microsoft C++ Build Tools including ATL, Rust and Inno Setup 6. Plugins used scoped directory junctions in ignored build folders; Developer Mode was not changed.

## Local Android 5.2.6+165 build

Both ARM64 and ARM32 release APKs were successfully compiled locally under WSL from commit `db6267a9e4b6e26e7217b18d72e656902beeadae`. Each uses `com.spotiflac.app`, version name 5.2.6 and base build number 165, and is signed with the existing project release key. Flutter's existing architecture-specific Android version codes are retained: 2165 for ARM64 and 1165 for ARM32. V1-V4 signatures, the expected certificate, native payload contents and 16 KB APK alignment passed verification. Matching source, checksums and private crash symbols were saved. Nothing was published.

The Rust mobile libraries and Android native audio code were compiled locally. The toolchain uses Flutter 3.47.7, Rust 1.99.0, Java 25, NDK 30 and CMake 4.1.2; Android plugins also required NDK 28.2 and older SDK platforms. Cargo lockfile normalization changed package ordering only: all 386 package records, versions, checksums and dependency relationships were compared. The normalized ordering is now committed to keep future builds stable. A phone was not connected, so physical installation, playback and commercial-provider/GUI tests remain pending.

## Remaining external work

- Corrected hosted 5.2.6+165 builds have passed for all platforms. Resolve the Linux compatibility issue below, then complete commercial-provider/GUI download and physical Android/iPhone installation/playback tests. Signed Android ARM64 and ARM32 packages are built and audited. The Windows x64 version-change installer test has passed. No authorized phone was connected; an emulator test is not being claimed. Linux, macOS and Windows ARM64 have build/audit results, but native installation and playback were not exercised on this Windows x64 host.
- Trusted Apple distribution/notarization and Windows signing require owner-held certificates or verified service accounts. Available Apple Developer and SignPath pages required sign-in, and no usable certificates were supplied. Self-signed certificates do not establish public distribution trust.
- The owner approved public source hosting on 2026-11-06. Anonymous access was verified, and the corrected-version release build started on standard free public-repository runners. No payment or spending-limit change was made. Build run: https://github.com/spotiflac-app/spotiflac/actions/runs/42238210013
- Corrected downloads draft 437551007 is staged in `spotiflac-app/spotiflac-releases`, with 18 verified assets: all platform packages, Android signature sidecars, two matching source archives, the iOS feed and unified checksums. It remains unpublished pending the external checks above. Original build draft 436671583 is explicitly quarantined; retired QA drafts remain unpublished. No GitHub token is embedded in the app.
- Website development remains deferred by the owner. Existing website download links are unchanged until spotiflac.com is ready.
- Optional Discord, OAuth, translation, funding and community integrations remain disabled or unconfigured until project-owned accounts are supplied.

## Licensing

This is an independently maintained derivative. Brand and repository control
does not transfer copyright in inherited code. LICENSE, COPYING, NOTICE and
third-party notices remain. Dated modifications are recorded. Distribute source
and notices as required by the existing license when distributing binaries.

See [Release setup](RELEASE_SETUP.md) for operational instructions.


## Corrected release build completed

Linux compatibility was resolved on 2026-11-07 in
[run 42369265356](https://github.com/spotiflac-app/spotiflac/actions/runs/42369265356),
commit `fa7b65a91bf76e55e273c56cf8efe5ba3c783eda`. Both native architectures
passed glibc auditing, AppImage/Debian packaging, clean Ubuntu 24.04
installation and native-library/FFmpeg CLI execution. SMB retains the
dart_smb2 0.1.3/r8 source and patch set; the FFmpeg tools are rebuilt from
pinned LGPL sources. Original Linux assets in draft 436671583 remain
quarantined. Non-Linux packages below retain their original immutable
source; the downloads draft must include both corresponding archives.
Package inspection verified product versions/identities, Windows PE/AOT
architectures, universal macOS Mach-O files, and Android JAR signatures
against the project certificate. This does not replace device/GUI tests.

All seven platform builds and release assembly passed in [run 42238210013](https://github.com/spotiflac-app/spotiflac/actions/runs/42238210013), using source commit `9553af072d78936efe03ea80e3d3ae69b041d4f8`. The draft contains Android ARM32/ARM64, Windows x64/ARM64, Linux x64/ARM64, universal macOS and the unsigned iOS IPA. Version remains 5.2.6+165. Standard public-repository runners were used; no billing settings were changed.

The original draft remains quarantined because its Linux binaries have the GLIBC conflict described above. The corrected run resolves that conflict and verifies declared runtime dependencies. Phone tests and trusted Apple/Windows distribution signing remain outstanding; build and package checks do not establish installation or playback on every platform.
