# SpotiFLAC project and release status

Updated 2026-11-08.

- Website: https://spotiflac.com
- Source: https://github.com/spotiflac-app/spotiflac
- Downloads: https://github.com/spotiflac-app/spotiflac-releases/releases/tag/v5.2.6
- Product version: **5.2.6+165**
- Application namespace: `com.spotiflac.app`

## Published application

The application, native bindings, platform metadata and installers use SpotiFLAC
and the `com.spotiflac.app` namespace. The published product version is 5.2.6+165;
the About screen and diagnostics also retain build 165. Copyright and contributor
notices are retained with the corresponding source and third-party components.

The owner approved public source hosting on 2026-11-06. The final release was
published on 2026-11-08 in the separate project-owned downloads repository.
All 18 assets were compared with local SHA-256 digests after upload: Android
ARM32/ARM64 APKs and signature sidecars, Windows x64/ARM64 installers and portable
ZIPs, Linux x64/ARM64 AppImages and Debian packages, universal macOS DMG,
unsigned iOS IPA, two source archives, the iOS feed and unified checksum manifest.

The release source archives contain commit
`7807ddf4d48ddcfd4766f804c7b9d72a964597b7`, including the final build recovery
recipes. The platform builds below have identical application, asset, Rust and
dependency source trees; subsequent differences concern packaging recovery.

| Final package | Successful platform job |
| --- | --- |
| Android ARM32/ARM64 | [42473372828](https://github.com/spotiflac-app/spotiflac/actions/runs/42473372828) |
| iOS and universal macOS | [42471535967](https://github.com/spotiflac-app/spotiflac/actions/runs/42471535967) |
| Windows x64 | [42472799232](https://github.com/spotiflac-app/spotiflac/actions/runs/42472799232) |
| Windows ARM64 | [42474564826](https://github.com/spotiflac-app/spotiflac/actions/runs/42474564826) |
| Linux x64/ARM64 | [42473371302](https://github.com/spotiflac-app/spotiflac/actions/runs/42473371302) |

Some multi-platform runs contain failed, superseded jobs for other targets; the
table identifies only the successful jobs used for the published packages.
Earlier QA binaries with an incorrect version and superseded Linux binaries
remain quarantined. Do not relabel or distribute those earlier artifacts.

## Updates, configuration and signing

Official builds use `spotiflac-app/spotiflac-releases` for unauthenticated release
checks and `config/app.json`. No GitHub token is embedded in the application.
Announcements are empty and funding is disabled. Inherited payment accounts,
community links and optional original-operator integrations were removed or disabled.
Discord and the optional built-in Apple lyrics backup require project-owned setup.

The public iOS source is populated from the published IPA and available at
https://raw.githubusercontent.com/spotiflac-app/spotiflac-releases/main/apps.json.
The source repository's `apps.json` is a versioned metadata snapshot. Public
feed updates are written to the downloads repository by the verified publisher.

Android uses the project release key; encrypted signing material and passwords
remain outside source control. Keep that key for future application updates.
iOS is unsigned and requires signing before installation. macOS is ad-hoc signed
and not notarized. Windows packages are unsigned. Trusted Apple/Windows signing
is optional follow-up work requiring owner-held accounts or certificates.

## Verification and practical limits

Final artifact ZIP digests, package manifests, published asset digests, Android
project signatures, and Android/Windows/iOS package identities and versions were
verified. Final Windows jobs audit native PE/AOT architectures and bundled tools;
final Linux jobs audit GLIBC compatibility and package dependencies.

Earlier native startup checks covered Windows x64/ARM64, macOS Intel/Apple Silicon,
and Linux x64/ARM64 on Ubuntu 22.04 and 24.04. They apply to the package hashes
tested in those runs, rather than constituting a repeated GUI test of every final
package. Isolated provider tests used synthetic loopback audio. Physical phone
installation, hardware audio and commercial-provider GUI coverage are not claimed.
Build and package verification do not establish those runtime results.

Linux packaging rebuilds the original dart_smb2 0.1.3/r8 native sources and pinned
LGPL FFmpeg sources against Ubuntu 22.04. It rejects GLIBC_PRIVATE and GLIBC
requirements above 2.35. Debian packages explicitly declare dynamically loaded
EGL/GLES dependencies; AppImages still use host desktop runtime libraries.
Verified native components were reused only after source/provenance checks.
The pinned SQLite binary is checked against its upstream SHA-256 before reuse.

Standard public GitHub runners were used. Earlier private-runner account limits
were superseded; no payment or spending-limit settings were changed.

## Website deployment

Download links and release synchronization were updated in the separate website
repository, `carrompool234/spotiflacc`, at commit
`04f74a2e24551bf8329663b9983d73b0e0dff5ef`. Checks matched package URLs across
eight pages against the published release. The existing local redesign was untouched.

Vercel reported **Deployment was blocked** for
[this deployment](https://vercel.com/team-spot/spotiflacc/AwW5HSjxB6tuTb5DRfa8rVn1Gg7n).
The live site's download links still pointed to upstream packages at the last
verification. Resolving that hosting block is the remaining deployment task.

## Licensing

LICENSE, COPYING, NOTICE and third-party notices are retained. Distribute the
matching source and notices with binaries as required by the existing licenses.
See [release setup](RELEASE_SETUP.md) for build and distribution instructions.
