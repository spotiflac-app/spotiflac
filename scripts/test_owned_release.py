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
            files=sorted(root.glob('SpotiFLAC-*'))
            (root/'SHA256SUMS.txt').write_text(''.join(f'{hashlib.sha256(p.read_bytes()).hexdigest()}  {p.name}\n' for p in files))
            self.assertEqual(len(prepare(root,'v1.0.0')),2)
            self.assertEqual(len((root/'SHA256SUMS.txt').read_text().splitlines()),2)
            self.assertIn('macos-universal.dmg',(root/'RELEASE_NOTES.md').read_text())

    def test_missing_manifest_cannot_create_verified_release(self):
        with tempfile.TemporaryDirectory() as temp:
            root=Path(temp)
            (root/'SpotiFLAC-v1.0.0-arm64.apk').write_bytes(b'unverified')
            with self.assertRaisesRegex(ValueError,'Missing input checksum'):
                prepare(root,'v1.0.0')
            self.assertFalse((root/'SHA256SUMS.txt').exists())
            self.assertFalse((root/'RELEASE_NOTES.md').exists())

    def test_unlisted_package_cannot_enter_existing_manifest(self):
        with tempfile.TemporaryDirectory() as temp:
            root=Path(temp)
            apk=root/'SpotiFLAC-v1.0.0-arm64.apk';apk.write_bytes(b'verified')
            manifest=root/'SHA256SUMS-android.txt'
            original=f'{hashlib.sha256(apk.read_bytes()).hexdigest()}  {apk.name}\n'
            manifest.write_text(original)
            (root/'SpotiFLAC-v1.0.0-ios-unsigned.ipa').write_bytes(b'unverified')
            with self.assertRaisesRegex(ValueError,'missing input checksums'):
                prepare(root,'v1.0.0')
            self.assertEqual(manifest.read_text(),original)
            self.assertFalse((root/'SHA256SUMS.txt').exists())

    def test_all_platform_manifests_cover_signature_sidecars(self):
        with tempfile.TemporaryDirectory() as temp:
            root=Path(temp)
            for platform,labels in [('android',['arm64.apk','arm64.apk.idsig']),('ios',['ios-unsigned.ipa'])]:
                lines=[]
                for label in labels:
                    p=root/f'SpotiFLAC-v1.0.0-{label}';p.write_bytes(label.encode())
                    lines.append(f'{hashlib.sha256(p.read_bytes()).hexdigest()}  {p.name}\n')
                (root/f'SHA256SUMS-{platform}.txt').write_text(''.join(lines))
            self.assertEqual(len(prepare(root,'v1.0.0')),3)

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
            update(feed,ipa,'v1.0.0','spotiflac-app/spotiflac')
            item=json.loads(feed.read_text())['apps'][0]
            self.assertEqual(item['size'],ipa.stat().st_size)
            self.assertEqual(item['bundleIdentifier'],'com.spotiflac.app')
            self.assertTrue(item['downloadURL'].endswith(ipa.name))

    def test_unrelated_ipa_cannot_enter_feed(self):
        with tempfile.TemporaryDirectory() as temp:
            root=Path(temp);feed=root/'apps.json';feed.write_text('{"apps": []}');ipa=root/'wrong.ipa'
            with zipfile.ZipFile(ipa,'w') as z:z.writestr('Payload/Runner.app/Info.plist',plistlib.dumps({'CFBundleIdentifier':'other.app'}))
            with self.assertRaises(ValueError):update(feed,ipa,'v1.0.0','spotiflac-app/spotiflac')
            self.assertEqual(json.loads(feed.read_text())['apps'],[])

if __name__=='__main__':unittest.main()
