# SpotiFLAC setup

Website: https://spotiflac.com
Source: https://github.com/spotiflac-app/spotiflac
Downloads: https://github.com/spotiflac-app/spotiflac-releases/releases/tag/v5.2.7
Namespace: `com.spotiflac.app`
Published product version: `5.2.7+166`

The application, native bindings, platform metadata and installers use the
SpotiFLAC identity. The About screen and diagnostics identify build 166.

Official mobile and desktop builds check the project-owned downloads repository.
Announcements use that repository's `config/app.json`; funding is disabled.
`SPOTIFLAC_CONFIG_URL` can override the configuration source, while an empty
value disables requests and cached announcements. No GitHub credential is
embedded in the app. The iOS source now points to the published unsigned IPA.

Discord and the optional original-operator lyrics backup remain disabled until
project-owned integrations are configured. Third-party providers retain their
credits and depend on their respective services.

See [release setup](RELEASE_SETUP.md) for signing, building and publishing, and
[ownership status](OWNERSHIP_HANDOVER.md) for current verification and the blocked
website deployment. Keep LICENSE, COPYING, NOTICE and third-party notices.
