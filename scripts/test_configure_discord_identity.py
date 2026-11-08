import plistlib
from pathlib import Path
import tempfile
import unittest
from configure_discord_identity import configure


class DiscordCallbackTest(unittest.TestCase):
    def test_callback_matches_native_identity_without_changing_app_link(self):
        with tempfile.TemporaryDirectory() as folder:
            path = Path(folder) / 'Info.plist'
            original = {'CFBundleIdentifier': 'com.spotiflac.app', 'CFBundleURLTypes': [{'CFBundleURLSchemes': ['spotiflac']}, {'CFBundleURLSchemes': ['discord-0']}]}
            path.write_bytes(plistlib.dumps(original))
            configure(path, '123456789012345678')
            actual = plistlib.loads(path.read_bytes())
            self.assertEqual(actual['CFBundleURLTypes'][1]['CFBundleURLSchemes'], ['discord-123456789012345678'])
            self.assertEqual(actual['CFBundleURLTypes'][0], original['CFBundleURLTypes'][0])
            self.assertEqual(actual['CFBundleIdentifier'], 'com.spotiflac.app')
