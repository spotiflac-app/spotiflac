import unittest
from publish_distribution import parse_manifest, resolve_source_commit
from urllib.error import HTTPError

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


    def test_untagged_draft_requires_immutable_commit(self):
        sha = 'a' * 40
        class API:
            def api(self, method, path):
                if '/git/ref/' in path:
                    raise HTTPError('https://api.github.com/test', 404, 'missing', {}, None)
                return {'sha': sha}
        self.assertEqual(resolve_source_commit(API(), 'owner/source', {'draft': True, 'target_commitish': sha}, 'v1.0.0'), sha)
        for source in [{'draft': True, 'target_commitish': 'main'}, {'draft': False, 'target_commitish': sha}]:
            with self.assertRaises(HTTPError):
                resolve_source_commit(API(), 'owner/source', source, 'v1.0.0')

    def test_existing_tag_takes_precedence_over_draft_target(self):
        sha = 'b' * 40
        class API:
            def api(self, method, path):
                return {'object': {'type': 'commit', 'sha': sha}}
        self.assertEqual(resolve_source_commit(API(), 'owner/source', {'draft': True, 'target_commitish': 'main'}, 'v1.0.0'), sha)

if __name__ == '__main__':
    unittest.main()
