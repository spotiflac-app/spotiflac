# Optional SpotiFLAC Discord integration

Disabled in project builds until a project-owned Discord application and an
authorized SDK are configured. The inherited application ID, OAuth registration,
encrypted SDK payload, and decryption-secret dependency are not used.

The plugin reports that the SDK is unavailable in builds without the SDK. This
does not affect playback. See `docs/RELEASE_SETUP.md` for explicit activation and
application ID settings. Retain the SDK vendor's license notices if enabling it.
