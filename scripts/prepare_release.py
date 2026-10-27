"""Verify downloaded build manifests and create one release manifest and notes."""
import argparse
import hashlib
from pathlib import Path
import re

def digest(path):
    value=hashlib.sha256()
    with path.open('rb') as stream:
        for chunk in iter(lambda:stream.read(1024*1024),b''):value.update(chunk)
    return value.hexdigest()

def prepare(directory,version):
    directory=Path(directory).resolve()
    if not re.fullmatch(r'v?\d+\.\d+\.\d+(?:[.-][0-9A-Za-z.-]+)?',version):
        raise ValueError('Invalid release version')
    packages=sorted(p for p in directory.glob('SpotiFLAC-*') if p.is_file())
    if not packages:raise ValueError('No release packages')
    if any(p.is_symlink() or not p.name.startswith(f'SpotiFLAC-{version}-') for p in packages):
        raise ValueError('Unexpected package version or symbolic link')
    for manifest in sorted(directory.glob('SHA256SUMS*.txt')):
        for line in manifest.read_text(encoding='utf-8').splitlines():
            if not line.strip():continue
            match=re.fullmatch(r'([0-9a-fA-F]{64}) [ *](.+)',line)
            if not match:raise ValueError(f'Invalid checksum line in {manifest.name}')
            expected,name=match.groups()
            if Path(name).name!=name or name not in {p.name for p in packages}:
                raise ValueError('Checksum references an unexpected file')
            target=directory/name
            if target.is_symlink() or digest(target)!=expected.lower():
                raise ValueError(f'Checksum mismatch: {name}')
    checksum=''.join(f'{digest(p)}  {p.name}\n' for p in packages)
    (directory/'SHA256SUMS.txt').write_text(checksum,encoding='utf-8')
    notes=[f'# SpotiFLAC {version}','', 'Website: https://spotiflac.com',
           'Source: https://github.com/spotiflacapp/spotiflac','',
           'Only packages successfully built in this workflow are listed.','',
           '| File | Bytes |','|---|---:|']
    notes += [f'| `{p.name}` | {p.stat().st_size} |' for p in packages]
    notes += ['', '`SHA256SUMS.txt` covers every file listed above.', '',
              'Android packages are signed with the project release key. The iOS IPA is unsigned and needs signing before installation. Desktop signing depends on the project signing configuration.']
    (directory/'RELEASE_NOTES.md').write_text('\n'.join(notes)+'\n',encoding='utf-8')
    return packages

if __name__=='__main__':
    parser=argparse.ArgumentParser()
    parser.add_argument('directory');parser.add_argument('--version',required=True)
    args=parser.parse_args()
    print(f'Prepared {len(prepare(args.directory,args.version))} release assets')
