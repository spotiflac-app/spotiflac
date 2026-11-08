# Security policy

## Reporting a vulnerability

Report vulnerabilities privately through
[GitHub private vulnerability reporting](https://github.com/spotiflac-app/spotiflac/security/advisories/new).
Include the affected version, reproduction steps and a minimal example where possible.
Do not include account passwords, signing keys, access tokens or private media.

Keep exploit details out of public issues until maintainers have assessed the
report and coordinated a fix. Ordinary bugs can use the public issue templates.

## Supported releases

Security fixes are developed on `main` and distributed in the latest published
release in [the downloads repository](https://github.com/spotiflac-app/spotiflac-releases/releases).
Older releases should be updated before reporting an issue that has already been fixed.

Verify packages against the SHA-256 manifest attached to the same release.
Never distribute or install packages whose checksums do not match that manifest.
