# SpotiFLAC ownership status

Updated 2026-11-04.
Website: https://spotiflac.com
Repository: https://github.com/spotiflac-app/spotiflac

## Implemented in the local source

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

## Requires external access or verification

- Source is uploaded to the private project repository on `main`.
- All four Android signing secrets are configured in GitHub Actions.
- Run CI and compile on the intended operating systems. Local source checks and
  packaging tests can pass without proving Flutter/native builds work.
- Configure Apple/Windows trusted signing using accounts and certificates you
  own if required. No certificate purchase or external account creation occurred.
- Update and deploy the existing website after its source/hosting is accessible.
  It must use this repository's release feed and stop advertising inherited
  downloads. The website itself is not modified by changes to this source tree.
- Register any optional Discord, OAuth, translation, payment or community
  accounts you wish to enable. They are not fabricated or silently reused.

## Licensing

This is an independently maintained derivative. Brand and repository control
does not transfer copyright in inherited code. LICENSE, COPYING, NOTICE and
third-party notices remain. Dated modifications are recorded. Distribute source
and notices as required by the existing license when distributing binaries.

See [Release setup](RELEASE_SETUP.md) for operational instructions.
