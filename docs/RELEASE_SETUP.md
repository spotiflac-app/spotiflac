# SpotiFLAC release setup

## Current release

Source: `spotiflac-app/spotiflac`, branch `main`.
Downloads: [SpotiFLAC v5.2.7](https://github.com/spotiflac-app/spotiflac-releases/releases/tag/v5.2.7),
product version **5.2.7+166**. See [project status](OWNERSHIP_HANDOVER.md) for
exact build provenance, validation and signing status.
Development source targets **5.3.1+167**. Complete [account integration setup](FEATURE_SETUP.md)
before building a full release; the examples below target that development version.

Use the Flutter and Rust versions pinned in `.fvmrc` and
`rust_backend/rust-toolchain.toml`. Keep the lockfiles and existing license
notices. Update `pubspec.yaml`, `AppInfo.version`, `AppInfo.buildNumber` and the
changelog together. Release preflight rejects inconsistent versions:

```text
python scripts/check_release_version.py --version v5.3.1
```

## Release workflow

Run `.github/workflows/release.yml` at the intended commit with the matching
version. The normal workflow builds every platform, verifies native bundles,
records per-platform input checksums and assembles one unified source draft.
The draft identifies its immutable source commit. Every package and Android
signature sidecar must be covered by the input manifests.

Manual runs also support `build_only`, `linux_only`, `windows_only` and
`android_only` for isolated build recovery. A partial build is not a complete
multi-platform release. Require successful jobs for every advertised platform.
Do not relabel historical packages or replace a published binary.

## Signing

Android release jobs require `KEYSTORE_BASE64`, `KEY_ALIAS`,
`KEYSTORE_PASSWORD` and `KEY_PASSWORD`. Back up the project key and passwords
privately, retain the same key for updates, and verify the actual certificate
and signature schemes. The release workflow rejects missing signing credentials.
Never commit signing material or private symbols.

The standard iOS artifact is an unsigned IPA for signing/sideloading, macOS is
ad-hoc signed without notarization, and Windows packages are unsigned. This
setup does not require purchasing trusted Apple/Windows signing credentials.

Optional trusted macOS signing reads `MACOS_SIGNING_P12_BASE64` and
`MACOS_SIGNING_P12_PASSWORD`. Optional Windows SignPath signing reads
`SIGNPATH_API_TOKEN` and the organization/project/policy variables referenced
in the workflow. Enable these only with valid project-owned credentials and
configuration. App Store distribution additionally requires Apple's provisioning
and distribution process.

## Package validation and publication

CI runs Flutter analysis/tests, applicable Rust/mobile checks and all Python
release/configuration suites. The protected main branch requires the aggregate
`CI required checks` gate. Desktop checks build both Windows/Linux architectures
and the universal macOS application.

After a complete Release run succeeds, dispatch
`.github/workflows/validate-release-packages.yml` with its run ID, full source
commit, product version and build number. It verifies build provenance and tests
the actual artifacts on native hosted runners. Windows checks include installer
upgrade and preference preservation. macOS checks include DMG/signature integrity
and native startup. Linux checks include Debian installation, dynamic libraries
and rendered startup on Ubuntu 22.04 and 24.04 for both architectures.

These checks do not establish physical-phone installation, hardware audio or
commercial-provider GUI coverage. See their uploaded evidence for exact results.

Stage a downloads draft using an authenticated owner checkout:

```text
python scripts/publish_distribution.py --tag v5.3.1 --directory PATH_TO_REVIEW_PACKAGES
```

The publisher verifies every package digest, resolves the exact source commit,
includes matching source and license notices, derives iOS metadata from the IPA,
and verifies uploaded assets. It refuses to overwrite different existing assets.
Credentials stay in the environment or Git credential manager.

After the chosen package checks pass, publish the verified draft:

```text
python scripts/publish_distribution.py --tag v5.3.1 --directory PATH_TO_REVIEW_PACKAGES --publish
```

Replace the example version with the version actually built. `--publish`
rechecks exact remote names and digests, publishes in the downloads repository
and refreshes its stable `apps.json`. Preview releases do not replace the stable
feed. Repeating the command can resume a feed write if all immutable assets
still match. The source build release remains a draft. Repository visibility
and website deployment are not changed by the publisher.

After publication, verify the public release/latest API, package metadata,
checksums and iOS feed. Update README release links, the source metadata snapshot
and project status through a documentation pull request.

## Runtime configuration

Official builds read releases and `config/app.json` from
`spotiflac-app/spotiflac-releases`. Announcements are empty and funding is
disabled until project-owned configuration is supplied. No GitHub token is
compiled into the app. Generate public endpoints for a local release with:

```text
python scripts/prepare_release_config.py --repository spotiflac-app/spotiflac-releases
```

Pass `--dart-define-from-file=.release-defines.json` to Flutter.
`DISTRIBUTION_REPO` can override the workflow's default downloads host.
The stable iOS source is
`https://raw.githubusercontent.com/spotiflac-app/spotiflac-releases/main/apps.json`;
metadata comes from the actual IPA. The source repository copy is a snapshot.

Discord is disabled by default. Enabling it requires an authorized SDK,
project-owned application IDs, `SPOTIFLAC_DISCORD_SDK=1` and
`--dart-define=SPOTIFLAC_DISCORD_ENABLED=true`. Desktop native builds read
`SPOTIFLAC_DISCORD_CLIENT_ID`; mobile builds read
`SPOTIFLAC_DISCORD_APPLICATION_ID`. The optional built-in Apple lyrics backup
requires a project-controlled HTTPS `SPOTIFLAC_APPLE_LYRICS_URL` implementing the
expected API. Extension OAuth callbacks use `spotiflac://` as required.

Website publication is currently deferred and managed separately.

## Local builds

Windows builds need Visual Studio 2022 C++ Build Tools with
`Microsoft.VisualStudio.Workload.VCTools` and `Microsoft.VisualStudio.Component.VC.ATL`,
Rust, Inno Setup 6, and working Flutter plugin links. Apply
`scripts/prepare_flutter_sdk.dart`, generate release defines and run version
preflight before building. For x64:

```text
flutter build windows --release --build-name=5.3.1 --build-number=167 --dart-define-from-file=.release-defines.json
```

Audit with `scripts/check_windows_bundle.ps1`, then package with
`scripts/package_windows.ps1 -Version v5.3.1 -Arch x64`.

Android scripts run in Linux or WSL. Use the toolchain versions configured in
the release workflow, keep the checkout and caches on a Linux filesystem, fetch
locked dependencies, apply the Flutter SDK patches and run
`scripts/build_android.sh` with the release defines. Let the release build
regenerate plugin registration; a generic pub get followed by `--no-pub` can
retain test-only registration. Verify package identity, version name/code,
certificate, alignment, signature schemes and `scripts/check_backend_apk.py`.

Linux recipes build pinned LGPL FFmpeg and dart_smb2 sources on Ubuntu 22.04.
`verify_linux_runtime.py` rejects GLIBC_PRIVATE and GLIBC requirements above
2.35. Debian packaging fails on unresolved dependencies and declares dynamic
EGL/GLES dependencies. AppImages still require host desktop runtime libraries.
`stage_verified_sqlite.py` checks the pinned upstream SQLite hash. Rebuild native
components whenever their source or dependency graph changes; recovery recipes
may reuse components only after exact source and binary provenance checks.
