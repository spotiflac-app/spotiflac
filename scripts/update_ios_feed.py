"""Populate the source feed only from a real, successfully built IPA."""
import argparse
from datetime import datetime,timezone
import json
from pathlib import Path
import plistlib
import re
import zipfile

def update(feed,ipa,version,repository):
    if not re.fullmatch(r'[\w.-]+/[\w.-]+',repository):raise ValueError('Invalid repository')
    if not re.fullmatch(r'v?\d+\.\d+\.\d+(?:[.-][0-9A-Za-z.-]+)?',version):raise ValueError('Invalid version')
    ipa=Path(ipa)
    with zipfile.ZipFile(ipa) as archive:
        info=next(name for name in archive.namelist() if re.fullmatch(r'Payload/[^/]+\.app/Info.plist',name))
        bundle=plistlib.loads(archive.read(info))['CFBundleIdentifier']
    if bundle!='com.spotiflac.app':raise ValueError('IPA has an unexpected application identity')
    feed=Path(feed);data=json.loads(feed.read_text(encoding='utf-8'))
    data['apps']=[{
        'name':'SpotiFLAC','bundleIdentifier':bundle,'developerName':'SpotiFLAC',
        'version':version.removeprefix('v'),'versionDate':datetime.now(timezone.utc).date().isoformat(),
        'downloadURL':f'https://github.com/{repository}/releases/download/{version}/{ipa.name}',
        'localizedDescription':'SpotiFLAC music player and library manager. https://spotiflac.com',
        'iconURL':f'https://raw.githubusercontent.com/{repository}/main/assets/images/logo.png',
        'size':ipa.stat().st_size,
    }]
    feed.write_text(json.dumps(data,indent=2)+'\n',encoding='utf-8')

if __name__=='__main__':
    p=argparse.ArgumentParser();p.add_argument('--ipa',required=True);p.add_argument('--version',required=True)
    p.add_argument('--repository',required=True);p.add_argument('--feed',default='apps.json');a=p.parse_args()
    update(a.feed,a.ipa,a.version,a.repository)
