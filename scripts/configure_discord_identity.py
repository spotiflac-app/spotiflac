"""Set the iOS OAuth callback to the same project ID as the native SDK."""
import argparse
import os
from pathlib import Path
import plistlib
import re


def configure(path, application):
    if not re.fullmatch(r'[1-9][0-9]{5,24}', application):
        raise ValueError('A project Discord application ID is required')
    data = plistlib.loads(path.read_bytes())
    count = 0
    for entry in data.get('CFBundleURLTypes', []):
        schemes = entry.get('CFBundleURLSchemes', [])
        for index, scheme in enumerate(schemes):
            if scheme.startswith('discord-'):
                schemes[index] = f'discord-{application}'
                count += 1
    if count != 1:
        raise ValueError('Expected exactly one Discord callback scheme')
    path.write_bytes(plistlib.dumps(data, sort_keys=False))


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--ios-plist', type=Path, required=True)
    args = parser.parse_args()
    configure(args.ios_plist, os.environ.get('SPOTIFLAC_DISCORD_APPLICATION_ID', ''))
