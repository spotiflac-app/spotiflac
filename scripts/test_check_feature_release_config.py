import unittest
from check_feature_release_config import validate


class FullReleaseConfigurationTest(unittest.TestCase):
    def setUp(self):
        self.environment = {
            'SPOTIFLAC_DISCORD_APPLICATION_ID': '123456789012345678',
            'LASTFM_API_KEY': 'example-key',
            'LASTFM_API_SECRET': 'example-secret',
            'MOBILE_BUILD': 'true',
            'DISCORD_MOBILE_SDK_PASSPHRASE': 'example-passphrase',
        }

    def test_full_release_requires_every_feature_dependency(self):
        validate(self.environment)
        for name in ('SPOTIFLAC_DISCORD_APPLICATION_ID', 'LASTFM_API_KEY', 'LASTFM_API_SECRET', 'DISCORD_MOBILE_SDK_PASSPHRASE'):
            with self.subTest(name=name):
                incomplete = {key: value for key, value in self.environment.items() if key != name}
                with self.assertRaises(ValueError) as error:
                    validate(incomplete)
                self.assertNotIn('example-', str(error.exception))

    def test_desktop_does_not_require_the_mobile_sdk_archive(self):
        self.environment['MOBILE_BUILD'] = 'false'
        del self.environment['DISCORD_MOBILE_SDK_PASSPHRASE']
        validate(self.environment)

    def test_discord_identity_cannot_be_an_unconfigured_placeholder(self):
        for value in ('0', '', '123;echo test', '-123456'):
            self.environment['SPOTIFLAC_DISCORD_APPLICATION_ID'] = value
            with self.subTest(value=value), self.assertRaises(ValueError):
                validate(self.environment)
