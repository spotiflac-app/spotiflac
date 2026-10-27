import hashlib,json,plistlib,tempfile,unittest,zipfile
from pathlib import Path
from prepare_release import prepare
from update_ios_feed import update

class OwnedReleaseTest(unittest.TestCase):
    def test_mobile_and_desktop_share_one_verified_manifest(self):
        with tempfile.TemporaryDirectory() as temp:
            root=Path(temp)
            for label in ['arm64.apk','macos-universal.dmg']:
                (root/f'SpotiFLAC-v1.0.0-{label}').write_bytes(label.encode())
            apk=root/'SpotiFLAC-v1.0.0-arm64.apk'
            (root/'SHA256SUMS.txt').write_text(f'{hashlib.sha256(apk.read_bytes()).hexdigest()}  {apk.name}\n')
            self.assertEqual(len(prepare(root,'v1.0.0')),2)
            self.assertEqual(len((root/'SHA256SUMS.txt').read_text().splitlines()),2)
            self.assertIn('macos-universal.dmg',(root/'RELEASE_NOTES.md').read_text())

    def test_corrupt_package_cannot_be_published(self):
        with tempfile.TemporaryDirectory() as temp:
            root=Path(temp);name='SpotiFLAC-v1.0.0-arm64.apk';(root/name).write_bytes(b'changed')
            (root/'SHA256SUMS.txt').write_text(f'{"0"*64}  {name}\n')
            with self.assertRaises(ValueError):prepare(root,'v1.0.0')
            self.assertFalse((root/'RELEASE_NOTES.md').exists())

    def test_feed_uses_actual_size_and_identity(self):
        with tempfile.TemporaryDirectory() as temp:
            root=Path(temp);feed=root/'apps.json';feed.write_text('{"apps": []}')
            ipa=root/'SpotiFLAC-v1.0.0-ios-unsigned.ipa'
            with zipfile.ZipFile(ipa,'w') as z:z.writestr('Payload/Runner.app/Info.plist',plistlib.dumps({'CFBundleIdentifier':'com.spotiflac.app'}))
            update(feed,ipa,'v1.0.0','spotiflacapp/spotiflac')
            item=json.loads(feed.read_text())['apps'][0]
            self.assertEqual(item['size'],ipa.stat().st_size)
            self.assertEqual(item['bundleIdentifier'],'com.spotiflac.app')
            self.assertTrue(item['downloadURL'].endswith(ipa.name))

    def test_unrelated_ipa_cannot_enter_feed(self):
        with tempfile.TemporaryDirectory() as temp:
            root=Path(temp);feed=root/'apps.json';feed.write_text('{"apps": []}');ipa=root/'wrong.ipa'
            with zipfile.ZipFile(ipa,'w') as z:z.writestr('Payload/Runner.app/Info.plist',plistlib.dumps({'CFBundleIdentifier':'other.app'}))
            with self.assertRaises(ValueError):update(feed,ipa,'v1.0.0','spotiflacapp/spotiflac')
            self.assertEqual(json.loads(feed.read_text())['apps'],[])

if __name__=='__main__':unittest.main()
