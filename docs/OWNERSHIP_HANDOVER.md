# SpotiFLAC project and release status

Updated 2026-11-09.

- Website: https://spotiflac.com
- Source: https://github.com/spotiflac-app/spotiflac
- Downloads: https://github.com/spotiflac-app/spotiflac-releases/releases/tag/v5.2.7
- Product version: **5.2.7+166**
- Application namespace: `com.spotiflac.app`

## Published application

Development source targets **5.3.1+167** using the stable 5.3.1 feature baseline.
The currently published packages below remain 5.2.7. A full 5.3.1 release requires
the project Discord registration/mobile SDK and Last.fm credentials described in
[account integrations](FEATURE_SETUP.md).

SpotiFLAC 5.2.7 includes ZIP/rustls security patches, semantic prerelease update
ordering, and verified package publication. Android ARM32/ARM64 APKs, Windows
x64/ARM64 installers and portable ZIPs, Linux x64/ARM64 AppImages and Debian
packages, a universal macOS DMG and an unsigned iOS IPA are available.

The downloads release includes matching source, iOS metadata and a unified
SHA-256 manifest. Every uploaded asset is compared against its local digest.
LICENSE, COPYING, NOTICE and third-party notices accompany the matching source.

All platform packages were built in
[Release run 42494200414](https://github.com/spotiflac-app/spotiflac/actions/runs/42494200414)
from immutable commit `ebcc0041c20e594dec08c035215c5aa7f89232c3`.
Subsequent documentation and validation changes do not change those binaries.

## Updates, configuration and signing

Official builds use `spotiflac-app/spotiflac-releases` for public release checks
and `config/app.json`. No GitHub token is embedded in the application.
Announcements are empty and funding is disabled. Development source includes
Discord and Last.fm configuration, and uses the public Apple lyrics backup.

The stable iOS source is generated from the published IPA:
https://raw.githubusercontent.com/spotiflac-app/spotiflac-releases/main/apps.json.
The source repository's `apps.json` is a versioned metadata snapshot.

Android uses the project release key; private signing material remains outside
source control. Keep that key for future application updates. iOS is unsigned
and requires signing before installation. macOS is ad-hoc signed and not
notarized. Windows packages are unsigned. This release uses the existing
project distribution model; trusted Apple/Windows signing is optional.

## Verification and practical limits

Required CI and desktop build checks passed before the release preparation was
merged. [Package validation run 42527562102](https://github.com/spotiflac-app/spotiflac/actions/runs/42527562102)
uses disposable GitHub-hosted runners and checks:

- Windows x64/ARM64 native startup and upgrade from 5.2.6, preserving a settings marker.
- macOS Intel/Apple Silicon DMG integrity, universal binaries, ad-hoc signature integrity and native startup.
- Linux x64/ARM64 Debian installation, native library loading and rendered startup on Ubuntu 22.04 and 24.04.
- Android project certificate and V1-V4 signatures, package identities and versions; iOS bundle metadata and native backend checks.

Physical phone installation, hardware audio and commercial-provider GUI coverage
are not claimed. Native startup checks do not establish complete feature coverage.

Linux packaging builds pinned LGPL FFmpeg and dart_smb2 sources on Ubuntu 22.04.
It rejects GLIBC_PRIVATE and GLIBC requirements above 2.35. Debian packages declare
dynamically loaded EGL/GLES dependencies; AppImages use host desktop libraries.

Repository controls include secret scanning and push protection, Dependabot
alerts and security updates, private vulnerability reporting, and protected main
with required applicable CI checks. Pull requests are required; the sole
maintainer setup does not require a second reviewer. Standard public hosted
runners are used; no billing or spending-limit settings were changed.

## Website deployment

Website work is deferred at the owner's request. This release changes the app
and GitHub repositories only. The previous website source update at `04f74a2`
in `carrompool234/spotiflacc` remains subject to its separate Vercel deployment
block. Website publication is not part of this release.

## Licensing

Distribute the matching source and notices with binaries as required by the
existing licenses. See [release setup](RELEASE_SETUP.md) for build and
publication instructions, and [SECURITY.md](../SECURITY.md) for private reporting.
