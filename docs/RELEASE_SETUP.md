# SpotiFLAC release setup

## Repository and first release

The source is maintained at `spotiflac-app/spotiflac` on `main`. Use tag `v1.0.0`
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
for announcements. The private source copy is the initial template. Funding is disabled until valid
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

## Private development and public downloads

The development repository stays private. Public download hosting is prepared at
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

After the signed private draft finishes, stage its audited assets from a local
checkout with the project owner's Git credentials:

```text
python scripts/publish_distribution.py --tag v1.0.0 --directory PATH_TO_REVIEW_PACKAGES
```

This tool never publishes or changes repository visibility. It verifies every
package against the private build's checksum manifest, resolves the exact tagged
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
