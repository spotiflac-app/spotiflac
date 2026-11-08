# SpotiFLAC release setup

## Repository and published release

The source is maintained at `spotiflac-app/spotiflac` on `main`.
[SpotiFLAC v5.2.6](https://github.com/spotiflac-app/spotiflac-releases/releases/tag/v5.2.6)
was published on 2026-11-08 with product version 5.2.6+165 and 18 verified assets.
The original copyright and license notices remain in the source archives.
The pinned Flutter/Rust toolchains and operating-system runners build the
mobile and desktop packages. Draft releases combine every
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

The public `apps.json` now contains the published v5.2.6 IPA. Its bundle ID,
size, date and URL come from the real package. The source repository copy is
synchronized. The live source URL is
`https://raw.githubusercontent.com/spotiflac-app/spotiflac-releases/main/apps.json`.
For future releases, derive metadata from the actual IPA.

The website source now uses
`https://api.github.com/repos/spotiflac-app/spotiflac-releases/releases` and the
published SpotiFLAC download URLs. An empty release feed
should display that the first release is being prepared, without falling back
to another project's packages. Website deployment requires access to its source
and hosting; changing this app repository does not modify the existing website.
The website update was pushed as `04f74a2` in `carrompool234/spotiflacc`, but
Vercel blocked deployment. Live pages had not changed at the last verification.
See [ownership status](OWNERSHIP_HANDOVER.md#website-deployment).

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
https://github.com/spotiflac-app/spotiflac-releases. The v5.2.6 packages, matching source snapshots, checksums, icon, safe
announcement configuration and populated iOS feed are public. Future packages
remain drafts during validation. The separate website deployment is blocked
in Vercel; its source already contains the corrected download links.

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

For future releases, publish the verified downloads draft explicitly after the
chosen release checks. The v5.2.6 downloads release is already published. Its public release API becomes the app's unauthenticated update
feed. The AltStore source is the stable release asset URL
`https://github.com/spotiflac-app/spotiflac-releases/releases/latest/download/apps.json`;
it is generated from the actual IPA. No production download is advertised before
a release is published. Trusted signing still requires owner-held Apple or
Windows signing credentials; a self-signed certificate does not establish public
distribution trust.

## Current release verification

All final packages were built successfully, and all 18 published asset digests
were verified against the staged manifests. The About screen and diagnostics
retain build 165. Package identities remain `com.spotiflac.app` where applicable.
See [ownership status](OWNERSHIP_HANDOVER.md) for the exact final platform runs,
source provenance, signing status and verification limits.

Release preflight checks `pubspec.yaml`, `AppInfo.version`, `AppInfo.buildNumber`
and the requested tag before platform jobs start. Do not relabel historical QA
binaries. Android signing keys and private symbols stay outside source control.

The standalone provider smoke script exercises a shipped native library and
bundled FFmpeg tools with isolated synthetic HTTP audio. It does not establish
physical-phone, hardware-audio or commercial-provider GUI coverage.

## Local Windows build requirements

Windows x64 5.2.6+165 was compiled, packaged and installer-upgrade tested locally. Hosted Actions billing is not required for that local build. Corrected hosted builds have now passed for all platforms; see the final build provenance in the ownership status.

Use the Flutter version pinned in `.fvmrc`, Visual Studio 2022 C++ Build Tools with `Microsoft.VisualStudio.Workload.VCTools` and `Microsoft.VisualStudio.Component.VC.ATL`, Rust for the media-control plugin, and Inno Setup 6 for the installer. Flutter plugins also require working plugin-folder links. Apply `scripts/prepare_flutter_sdk.dart`, generate `.release-defines.json` and run `scripts/check_release_version.py --version v5.2.6` before building.

Build with `flutter build windows --release --build-name=5.2.6 --build-number=165 --dart-define-from-file=.release-defines.json`, audit with `scripts/check_windows_bundle.ps1`, then package with `scripts/package_windows.ps1 -Version v5.2.6 -Arch x64`. Core native libraries may only be reused if their exact source and verified binary provenance are unchanged; otherwise rebuild them with the existing Rust/FFmpeg scripts.

## Local Android builds on Windows

The Android scripts run in Linux under WSL. Use the pinned Flutter 3.47.7 and Rust 1.99.0 with Java 25, SDK platform/build tools 37, NDK 30.0.16248370 and CMake 4.1.2. Plugins may additionally install NDK 28.2 and SDK platforms 34-36. Keep the build checkout, Flutter SDK, Cargo and Gradle caches on the Linux filesystem for reliable symlinks and build performance.

Prepare public endpoints with `python3 scripts/prepare_release_config.py --repository spotiflac-app/spotiflac-releases`, fetch the locked Flutter dependencies, and run `dart scripts/prepare_flutter_sdk.dart`. Set `ANDROID_NDK_HOME` to NDK 30 and build with `bash scripts/build_android.sh --lite --target lib/main.dart --dart-define-from-file=.release-defines.json`. The checked-in launcher assets are already branded. With pinned Flutter 3.47.7, allow the release build's pub step to regenerate native plugin registration; using `--no-pub` after a generic pub get can leave a test-only plugin in the release registrant.

Use the existing project signing key and the release workflow's signing procedure, then verify the signer certificate, all required signature schemes, version name/code, package identity, APK alignment and `scripts/check_backend_apk.py` results. A release build can use a debug key when no local release signing configuration is present; verify the actual certificate before distribution. Store signing material outside the repository, and retain the exact commit, checksums, Dart symbols and shrinking map privately. Physical phone and live-provider tests remain separate from package verification.


## Linux packaging and native reuse

Debian packaging requires `dpkg-shlibdeps` and fails on unresolved dependencies.
`verify_linux_runtime.py` rejects GLIBC_PRIVATE and GLIBC requirements above
2.35. Native recipes build pinned LGPL FFmpeg sources and the original
dart_smb2 0.1.3/r8 sources and patches on Ubuntu 22.04. Do not substitute the
superseded GLIBC-incompatible artifacts from the original draft.

Debian packages explicitly depend on `libgles2` and `libegl1`, which Flutter
opens dynamically, and recommend Mesa and desktop integration tools. AppImages
use host GTK, EGL/GLES, libsecret, playback and codec libraries; they do not
remove the runtime dependency requirements.

The final Linux branding build reuses verified native components from
[run 42468204499](https://github.com/spotiflac-app/spotiflac/actions/runs/42468204499)
after comparing native source and dependency trees. The final Windows branding
build follows the same provenance check against
[run 42238210013](https://github.com/spotiflac-app/spotiflac/actions/runs/42238210013).
`stage_verified_sqlite.py` additionally requires the pinned upstream SQLite hash.
Rebuild native components when their source or dependency graph changes.

Manual Release runs support `build_only`, `linux_only`, `windows_only` and
`android_only` to recover individual builds without replacing a release.
The final branding workflows are recovery recipes tied to the immutable
verified native runs above. Use the normal release workflow for changed native
source or dependencies.
