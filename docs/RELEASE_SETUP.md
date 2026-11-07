# SpotiFLAC release setup

## Repository and first release

The source is maintained at `spotiflac-app/spotiflac` on `main`. Use tag `v5.2.6`
for the first release. The pinned Flutter/Rust toolchains and operating-system
runners build the mobile and desktop packages. Draft releases combine every
successful platform, with one set of release notes and SHA256SUMS.txt.

The default is a draft release. Validate builds, signatures, fresh installation,
playback and downloads, then test an upgrade before setting the GitHub Actions
repository variable `PUBLISH_RELEASES` to `true` for future public releases.
Do not enable it merely to make a failed workflow appear successful.

## Android signing

A newly generated encrypted PKCS#12 key has been saved privately outside the
source tree. Back up that key and password securely. Configure these Actions
secrets using the private signing bundle: `KEYSTORE_BASE64`, `KEY_ALIAS`,
`KEYSTORE_PASSWORD`, `KEY_PASSWORD`. Keep the same key for future updates.
The workflow fails if signing credentials are missing; it does not publish a
debug-signed Android package. Do not commit signing keys or passwords.

## Apple and Windows signing

The iOS artifact is an unsigned IPA for signing/sideloading; publishing it is
not App Store distribution. Configure your Apple Developer team, certificates,
bundle IDs, provisioning, app groups and notarization if distributing signed
Apple builds. Current unsigned/ad-hoc desktop artifacts must be described as
such. Apple accounts and trusted certificates cannot be created from source.

macOS optionally reads `MACOS_SIGNING_P12_BASE64` and
`MACOS_SIGNING_P12_PASSWORD`. Windows optionally reads `SIGNPATH_API_TOKEN`
and the SignPath repository variables referenced in the workflow. Register
your own signing project and policies before enabling that integration.

## Configuration you control

Official releases read `config/app.json` from `spotiflac-app/spotiflac-releases`
for announcements. The source copy is the initial template. Funding is disabled until valid
project-owned methods are explicitly supplied. No old wallet or sponsorship
account is used. The repository configuration contains no credentials.

Discord is disabled. To restore it, obtain an authorized SDK and register your
own Discord application. Set the native application IDs and callbacks, build
with `SPOTIFLAC_DISCORD_SDK=1`, and enable the Dart integration with
`--dart-define=SPOTIFLAC_DISCORD_ENABLED=true`. Desktop uses the Rust build-time
environment variable `SPOTIFLAC_DISCORD_CLIENT_ID`; mobile native builds need
the `SPOTIFLAC_DISCORD_APPLICATION_ID` definition. All must refer to your same
registered application. The release jobs intentionally omit the SDK by default.

The optional built-in Apple lyrics backup is unavailable unless Rust is built
with a project-controlled HTTPS `SPOTIFLAC_APPLE_LYRICS_URL`. Implement the
expected API contract before configuring it. Other third-party providers can
still function independently. Extension OAuth applications must likewise use
accounts you control, with the `spotiflac://` callbacks registered as required.

## Feed and website

`apps.json` intentionally contains no apps until the first public iOS release.
The release workflow then derives its bundle ID, size, date and asset URL from
the actual IPA. Do not advertise nonexistent packages or inherited versions.

Point the website's release feed at
`https://api.github.com/repos/spotiflac-app/spotiflac-releases/releases` and remove its
inherited download URLs after verified releases exist. An empty release feed
should display that the first release is being prepared, without falling back
to another project's packages. Website deployment requires access to its source
and hosting; changing this app repository does not modify the existing website.

## Verification

Run `flutter pub get`, regenerate localization and bindings, `flutter analyze`,
`flutter test`, and the relevant native build/audit jobs. The four tests in
`scripts/test_owned_release.py` cover mixed-platform manifests, corrupted assets,
actual IPA metadata, and rejection of a different bundle ID. The Dart ownership
configuration tests cover disabled funding, no network requests when remote
configuration is disabled, and no native account initialization for disabled
Discord. A source audit is not a substitute for running those builds.

## Public development and downloads

The owner approved making the development repository public on 2026-11-06.
Its standard GitHub-hosted build runners use the free public-repository tier.
Public download hosting remains at
https://github.com/spotiflac-app/spotiflac-releases. Only its README, safe
announcement configuration, icon and empty placeholder feed are initially public.
Release packages and matching source snapshots stay in drafts during validation.
The existing website download links are unchanged while the website is developed.

Every official Release build generates `.release-defines.json` using
`scripts/prepare_release_config.py`. The `DISTRIBUTION_REPO` Actions variable can
override the default `spotiflac-app/spotiflac-releases` host. Mobile and desktop
updates and announcements use that host; no GitHub token is compiled into the app.
For a reproducible local distribution build, generate the file with
`python scripts/prepare_release_config.py --repository spotiflac-app/spotiflac-releases`
and pass `--dart-define-from-file=.release-defines.json` to Flutter.

After the release draft finishes, stage its audited assets from a local
checkout with the project owner's Git credentials:

```text
python scripts/publish_distribution.py --tag v5.2.6 --directory PATH_TO_REVIEW_PACKAGES
```

This tool never publishes or changes repository visibility. It verifies every
package against the build's checksum manifest, resolves the exact tagged
source commit, includes the matching source archive and license notices, and
creates a draft in the downloads repository. Existing different assets cannot
be silently overwritten. Credentials remain in the environment or local Git
credential manager. Do not store a broad personal token in the application.

Once the owner completes installation and update tests, publish the downloads
draft explicitly. Its public release API becomes the app's unauthenticated update
feed. The AltStore source is the stable release asset URL
`https://github.com/spotiflac-app/spotiflac-releases/releases/latest/download/apps.json`;
it is generated from the actual IPA. No production download is advertised before
a release is published. Trusted signing still requires owner-held Apple or
Windows signing credentials; a self-signed certificate does not establish public
distribution trust.

## Build verification (2026-11-05)

Android, iOS, Windows x64/ARM64, Linux x64/ARM64 and universal macOS builds
passed their CI checks. Flutter analysis and 3,557 tests passed; Rust Clippy
and 475 tests passed. See [ownership status](OWNERSHIP_HANDOVER.md) for run links,
skipped-test counts and distribution limitations. A successful CI build is not
a published production release. Existing website download links remain in place
while the website is under development, as requested by the owner.

## Current release status

The target is 5.2.6+165, matching the downloaded source version and build number. Previous test binaries embed an incorrect initial version and are retired QA artifacts, not 5.2.6 packages. Do not rename those binaries or reuse their source archive for the corrected release. Rebuild each platform from the corrected source. The earlier private-repository builds were blocked by account billing or its spending limit. With owner approval, the source repository is now public and the standard-runner release build has started successfully. No payment or spending-limit change was made.

The standalone provider smoke script exercises a shipped native library and bundled FFmpeg tools with an isolated synthetic HTTP provider. Pass `--library`, `--ffmpeg`, `--ffprobe` and `--report-dir` paths. It checks search, downloaded bytes, decoding and output-directory protection. Windows x64 and Linux x64 executions passed locally. Desktop and Release jobs now include those checks. This does not replace commercial-provider, GUI, physical phone or version-upgrade tests.

Release preflight checks `pubspec.yaml`, `AppInfo.version` and the requested tag before expensive platform jobs start. The build number must be present and positive. The new version checks have four passing unit tests.

## Local Windows build requirements

Windows x64 5.2.6+165 was compiled, packaged and installer-upgrade tested locally. Hosted Actions billing is not required for that local build. Corrected hosted builds have now passed for all platforms; see the completed-build status below.

Use the Flutter version pinned in `.fvmrc`, Visual Studio 2022 C++ Build Tools with `Microsoft.VisualStudio.Workload.VCTools` and `Microsoft.VisualStudio.Component.VC.ATL`, Rust for the media-control plugin, and Inno Setup 6 for the installer. Flutter plugins also require working plugin-folder links. Apply `scripts/prepare_flutter_sdk.dart`, generate `.release-defines.json` and run `scripts/check_release_version.py --version v5.2.6` before building.

Build with `flutter build windows --release --build-name=5.2.6 --build-number=165 --dart-define-from-file=.release-defines.json`, audit with `scripts/check_windows_bundle.ps1`, then package with `scripts/package_windows.ps1 -Version v5.2.6 -Arch x64`. Core native libraries may only be reused if their exact source and verified binary provenance are unchanged; otherwise rebuild them with the existing Rust/FFmpeg scripts.

## Local Android builds on Windows

The Android scripts run in Linux under WSL. Use the pinned Flutter 3.47.7 and Rust 1.99.0 with Java 25, SDK platform/build tools 37, NDK 30.0.16248370 and CMake 4.1.2. Plugins may additionally install NDK 28.2 and SDK platforms 34-36. Keep the build checkout, Flutter SDK, Cargo and Gradle caches on the Linux filesystem for reliable symlinks and build performance.

Prepare public endpoints with `python3 scripts/prepare_release_config.py --repository spotiflac-app/spotiflac-releases`, fetch the locked Flutter dependencies, and run `dart scripts/prepare_flutter_sdk.dart`. Set `ANDROID_NDK_HOME` to NDK 30 and build with `bash scripts/build_android.sh --lite --target lib/main.dart --dart-define-from-file=.release-defines.json`. The checked-in launcher assets are already branded. With pinned Flutter 3.47.7, allow the release build's pub step to regenerate native plugin registration; using `--no-pub` after a generic pub get can leave a test-only plugin in the release registrant.

Use the existing project signing key and the release workflow's signing procedure, then verify the signer certificate, all required signature schemes, version name/code, package identity, APK alignment and `scripts/check_backend_apk.py` results. A release build can use a debug key when no local release signing configuration is present; verify the actual certificate before distribution. Store signing material outside the repository, and retain the exact commit, checksums, Dart symbols and shrinking map privately. Physical phone and live-provider tests remain separate from package verification.


## Corrected release build completed

All seven platform builds and release assembly passed in [run 42238210013](https://github.com/spotiflac-app/spotiflac/actions/runs/42238210013), using source commit `9553af072d78936efe03ea80e3d3ae69b041d4f8`. The draft contains Android ARM32/ARM64, Windows x64/ARM64, Linux x64/ARM64, universal macOS and the unsigned iOS IPA. Version remains 5.2.6+165. Standard public-repository runners were used; no billing settings were changed.

The draft is not approved for distribution. A deeper local Ubuntu 22.04 runtime audit found that the pinned dart_smb2 0.1.3 library requires GLIBC 2.38, although the Linux Debian fallback dependency list advertises libc6 >= 2.35. AMR runtime dependencies also need package verification. Linux compatibility and package metadata must be resolved before publication. Build success alone does not establish installation or playback on every platform. Phone tests and trusted Apple/Windows distribution signing remain outstanding.

## Linux dependency validation

Debian packaging now requires dpkg-shlibdeps and fails if dependency resolution fails or returns an empty result. The previous fixed fallback could advertise libc6 >= 2.35 despite a bundled SMB library requiring GLIBC 2.38, and could omit codec runtime dependencies. Install the actual bundle runtime dependencies on the packaging host and resolve ABI compatibility before packaging. Do not publish the existing Linux draft assets based solely on a successful compilation. AppImage also uses system libraries and does not remove the bundled library's GLIBC requirement.
# Linux compatibility rebuild (2026-11-07)

The Ubuntu 22.04 bundle audit identified three incompatible ELF files:
`libsmb2.so` required GLIBC 2.38, while the static-glibc `ffmpeg` and
`ffprobe` imported GLIBC_PRIVATE resolver symbols and produced a libc6
upper bound below 2.36. The replacement recipes build FFmpeg from pinned
LGPL sources and the original dart_smb2 0.1.3/r8 source and patch set on
the native Ubuntu 22.04 release runners. No Dart dependency is upgraded.

`verify_linux_runtime.py` rejects GLIBC_PRIVATE and GLIBC requirements
above 2.35 before either AppImage or Debian packaging. Manual Release
runs can select `linux_only` to build both Linux architectures without
rebuilding successful platforms or changing the existing draft release.
The new artifacts still require hosted build and package verification.

