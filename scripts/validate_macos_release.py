#!/usr/bin/env python3
"""Audit an existing macOS release artifact and exercise native app startup."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import platform
import plistlib
import subprocess
import time


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('directory', type=Path)
    parser.add_argument('--report', type=Path, required=True)
    args = parser.parse_args()
    directory = args.directory.resolve()
    packages = list(directory.glob('SpotiFLAC-v5.2.6-macos-universal.dmg'))
    assert len(packages) == 1
    package = packages[0]
    manifest = (directory / 'SHA256SUMS-macos.txt').read_text().splitlines()
    expected = dict((line.split()[1], line.split()[0]) for line in manifest if line.strip())
    assert set(expected) == {package.name}
    digest = hashlib.sha256(package.read_bytes()).hexdigest()
    assert digest == expected[package.name]
    report = {'architecture': platform.machine(), 'package_sha256': digest,
              'version': '5.2.6+165', 'passed': False,
              'limits': 'Native startup only; no device audio, commercial provider or GUI interaction coverage.'}
    mount = directory / 'mount'
    mount.mkdir(exist_ok=True)
    process = None
    attached = False
    try:
        subprocess.run(['hdiutil', 'verify', str(package)], check=True)
        subprocess.run(['hdiutil', 'attach', '-readonly', '-nobrowse',
                        '-mountpoint', str(mount), str(package)], check=True)
        attached = True
        apps = list(mount.glob('*.app'))
        assert len(apps) == 1
        app = apps[0]
        info = plistlib.loads((app / 'Contents/Info.plist').read_bytes())
        assert info['CFBundleIdentifier'] == 'com.spotiflac.app'
        assert info['CFBundleShortVersionString'] == '5.2.6' and info['CFBundleVersion'] == '165'
        subprocess.run(['codesign', '--verify', '--deep', '--strict', '--verbose=2', str(app)], check=True)
        binary = app / 'Contents/MacOS' / info['CFBundleExecutable']
        for name in [binary, app / 'Contents/Resources/ffmpeg/ffmpeg',
                     app / 'Contents/Resources/ffmpeg/ffprobe']:
            subprocess.run(['lipo', str(name), '-verify_arch', 'x86_64', 'arm64'], check=True)
        for name in ['ffmpeg', 'ffprobe']:
            subprocess.run([str(app / 'Contents/Resources/ffmpeg' / name),
                            '-hide_banner', '-version'], check=True)
        # Hosted runners are disposable and contain no owner profile or accounts.
        with (directory / 'startup.log').open('wb') as log:
            process = subprocess.Popen([str(binary)], stdout=log, stderr=subprocess.STDOUT)
            time.sleep(20)
            report['startup_exit_code'] = process.poll()
            assert process.poll() is None, 'App exited during native startup; inspect startup.log'
            report['native_startup_20_seconds'] = True
            process.terminate()
            try:
                process.wait(timeout=15)
            except subprocess.TimeoutExpired:
                process.kill()
                process.wait(timeout=10)
                raise AssertionError('App did not shut down after SIGTERM')
        report['codesign_integrity'] = 'passed (ad hoc; not notarization)'
        report['passed'] = True
    finally:
        if process is not None and process.poll() is None:
            process.kill()
            process.wait(timeout=10)
        if attached:
            subprocess.run(['hdiutil', 'detach', str(mount)], check=True)
        args.report.parent.mkdir(parents=True, exist_ok=True)
        args.report.write_text(json.dumps(report, indent=2) + '\n')
    print(json.dumps(report))


if __name__ == '__main__':
    main()
