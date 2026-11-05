from pathlib import Path
import tempfile
import unittest
from check_release_version import validate


class ReleaseVersionTest(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)
        (self.root / 'lib/constants').mkdir(parents=True)
        self.write('5.2.6+165', '5.2.6')

    def write(self, specification, display):
        (self.root / 'pubspec.yaml').write_text('version: ' + specification + '\n')
        (self.root / 'lib/constants/app_info.dart').write_text("static const String version = '" + display + "';\n")

    def test_matching_version_retains_build_number(self):
        for tag in ('v5.2.6', '5.2.6'):
            self.assertEqual(validate(self.root, tag), {'tag': 'v5.2.6', 'version': '5.2.6', 'build_number': 165})

    def test_old_tag_cannot_mislabel_new_binary(self):
        with self.assertRaisesRegex(ValueError, 'does not match product'):
            validate(self.root, 'v1.0.0')

    def test_displayed_version_must_match_package(self):
        self.write('5.2.6+165', '1.0.0')
        with self.assertRaisesRegex(ValueError, 'AppInfo'):
            validate(self.root, 'v5.2.6')

    def test_build_number_is_required(self):
        self.write('5.2.6', '5.2.6')
        with self.assertRaisesRegex(ValueError, 'build number'):
            validate(self.root, 'v5.2.6')


if __name__ == '__main__':
    unittest.main()
