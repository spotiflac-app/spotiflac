import unittest
from publish_distribution import parse_manifest

class DistributionManifestTest(unittest.TestCase):
    def test_checksum_manifest_rejects_traversal_and_mixed_versions(self):
        for name in ['../SpotiFLAC-v1.0.0-arm64.apk', 'SpotiFLAC-v1.0.0-../key', 'SpotiFLAC-v2.0.0-arm64.apk', 'SpotiFLAC-v1.0.0-evil\\key.apk']:
            with self.subTest(name=name), self.assertRaises(ValueError):
                parse_manifest('0' * 64 + '  ' + name, 'v1.0.0')

    def test_manifest_rejects_duplicate_or_empty_assets(self):
        line = '0' * 64 + '  SpotiFLAC-v1.0.0-arm64.apk\n'
        differently_cased = line.replace('arm64.apk', 'ARM64.apk')
        for manifest in ['', line + line, line + differently_cased]:
            with self.assertRaises(ValueError):
                parse_manifest(manifest, 'v1.0.0')

if __name__ == '__main__':
    unittest.main()
