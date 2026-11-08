#!/usr/bin/env python3
"""Check an installed Debian bundle without requiring a display or audio device."""
import ctypes
import ctypes.util
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
playback_library = ctypes.util.find_library('mpv')
assert playback_library, 'Installed playback library could not be found'
ctypes.CDLL(playback_library)
for name in ('libsmb2.so', 'libspotiflac_desktop.so'):
    ctypes.CDLL(str(root / 'lib' / name))
# The upstream ARM64 plugin intentionally supplies no FFmpegKit library.
# Desktop FFmpegSupport uses the mandatory CLI tools on both architectures.
if (root / 'lib/libffmpegkit.so').exists():
    ctypes.CDLL(str(root / 'lib/libffmpegkit.so'))
for tool in ('ffmpeg', 'ffprobe'):
    result = subprocess.run([str(root / 'lib/ffmpeg' / tool), '-hide_banner', '-version'],
                            check=True, capture_output=True, text=True)
    assert '--enable-gpl' not in result.stdout and '--enable-nonfree' not in result.stdout
print(f'Installed bundle: {len(records)} ELF files resolved; playback, SMB and backend libraries loaded; FFmpeg CLI tools ran.')
