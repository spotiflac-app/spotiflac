#!/usr/bin/env python3
"""Check an installed Debian bundle without requiring a display or audio device."""
import ctypes
import os
from pathlib import Path
import subprocess

from verify_linux_runtime import audit


root = Path('/usr/lib/spotiflac')
records = audit(root, (2, 35))
assert not any(r['errors'] for r in records), records
env = {**os.environ, 'LD_LIBRARY_PATH': str(root / 'lib')}
for record in records:
    result = subprocess.run(['ldd', str(root / record['file'])],
                            capture_output=True, text=True, env=env)
    assert 'not found' not in result.stdout + result.stderr, (record, result.stdout, result.stderr)
ctypes.CDLL('libstdc++.so.6', mode=ctypes.RTLD_GLOBAL)
ctypes.CDLL('libmpv.so.2')
for name in ('libsmb2.so', 'libspotiflac_desktop.so', 'libffmpegkit.so'):
    ctypes.CDLL(str(root / 'lib' / name))
for tool in ('ffmpeg', 'ffprobe'):
    result = subprocess.run([str(root / 'lib/ffmpeg' / tool), '-hide_banner', '-version'],
                            check=True, capture_output=True, text=True)
    assert '--enable-gpl' not in result.stdout and '--enable-nonfree' not in result.stdout
print(f'Installed bundle: {len(records)} ELF files resolved; playback, SMB, backend, FFmpegKit and CLI libraries loaded.')
