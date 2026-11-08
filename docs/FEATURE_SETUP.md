# Account-backed feature setup

The application feature baseline is stable Mornye 5.3.1, commit
`e7a8f754a618d28ab0baf88ada3f65ab9d41534a`. SpotiFLAC uses its own
application namespace, branding, release host and remote configuration.
Original copyright, license and third-party credits remain intact.

Application code alone does not create the service registrations below.
The full Release workflow checks their presence before building; it does not
silently publish a mobile package without Discord support. CI can test native
code without the private mobile SDK, but does not establish a live SDK login.

## Discord

1. Create a SpotiFLAC application in the
   [Discord Developer Portal](https://discord.com/developers/applications).
   Add its numeric application ID as the GitHub repository variable
   `DISCORD_APPLICATION_ID`.
2. Follow Discord's [Social SDK setup](https://github.com/discord/discord-api-docs/blob/main/developers/discord-social-sdk/getting-started/partials/getting-started.mdx)
   to enable authorized SDK access. Configure the mobile OAuth callback
   `discord-YOUR_APP_ID:/authorize/callback` and the client settings required
   by that guide.
3. Obtain the official SDK version pinned in `scripts/prepare_discord_sdk.py`
   (currently `1.10.19337`). Verify the downloaded ZIP with:

   ```text
   python scripts/prepare_discord_sdk.py --archive PATH_TO_OFFICIAL_SDK_ZIP
   ```

4. Stage an authorized, symmetrically encrypted copy at
   `third_party/discord/discord-mobile-1.10.19337.zip.gpg`, and put its
   passphrase in the repository secret `DISCORD_MOBILE_SDK_PASSPHRASE`.
   A passphrase must match the staged archive; setting a new passphrase does
   not unlock an existing encrypted file. Keep plaintext SDK distributions
   outside source control and follow their distribution terms.

The release jobs use the same application ID for desktop RPC and the Android/iOS
SDK. The iOS callback is derived from that ID during the build. Desktop uses
local Discord RPC and does not require the mobile SDK archive.

## Last.fm

Register the application through the [Last.fm API account page](https://www.last.fm/api/account/create).
Add its credentials as GitHub repository secrets `LASTFM_API_KEY` and
`LASTFM_API_SECRET`. The release configuration helper passes both through the
ignored `.release-defines.json`; it does not print their values. Both are
required together. Use the project's own registration for its builds.

## Release and verification

Community links can be configured with the optional repository variables
`TELEGRAM_CHANNEL_URL` and `TELEGRAM_CHAT_URL`. Supply HTTPS links to the
project's actual channels. Unconfigured links are hidden rather than guessed.
The official website, source and issue links remain available independently.

After configuring the accounts, run the normal Release workflow for the
version in `pubspec.yaml`. The existing Android project signing key remains
required for compatible updates. Apple/Windows signing follows the documented
distribution model and is separate from these service registrations.

Require the existing CI gate, native builds, package checks and verified
publication process. Test Discord authorization/presence and Last.fm linking/
scrobbling with the actual project registrations before claiming live service
coverage. See [release setup](RELEASE_SETUP.md).
