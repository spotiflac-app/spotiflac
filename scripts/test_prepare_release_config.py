import unittest
import contextlib
import io
import json
import os
from pathlib import Path
import sys
import tempfile
from unittest.mock import patch
from prepare_release_config import main
from prepare_release_config import release_config

class ReleaseConfigurationTest(unittest.TestCase):
    def test_lastfm_definitions_are_written_without_logging_credentials(self):
        with tempfile.TemporaryDirectory() as folder:
            output = Path(folder) / 'defines.json'
            stdout = io.StringIO()
            with patch.dict(os.environ, {'LASTFM_API_KEY': 'test-key', 'LASTFM_API_SECRET': 'test-secret'}), patch.object(sys, 'argv', ['prepare_release_config.py', '--repository', 'owner/downloads', '--output', str(output)]), contextlib.redirect_stdout(stdout):
                main()
            config = json.loads(output.read_text())
            self.assertEqual(config['LASTFM_API_KEY'], 'test-key')
            self.assertEqual(config['LASTFM_API_SECRET'], 'test-secret')
            self.assertNotIn('test-key', stdout.getvalue())
            self.assertNotIn('test-secret', stdout.getvalue())

    def test_mobile_and_desktop_use_the_same_public_host(self):
        config = release_config('spotiflac-app/spotiflac-releases')
        self.assertEqual(config['SPOTIFLAC_GITHUB_REPO'], config['SPOTIFLAC_DESKTOP_GITHUB_REPO'])
        self.assertTrue(config['SPOTIFLAC_CONFIG_URL'].startswith('https://raw.githubusercontent.com/spotiflac-app/spotiflac-releases/'))
        self.assertFalse(any('TOKEN' in key or 'PASSWORD' in key for key in config))

    def test_missing_or_external_repository_is_rejected(self):
        for repository in ['', 'https://example.com/project', 'owner/repo/other', 'owner/..', '../repo', 'owner/repo\n--other']:
            with self.subTest(repository=repository), self.assertRaises(ValueError):
                release_config(repository)

if __name__ == '__main__':
    unittest.main()
