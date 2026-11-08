"""Seed the sqlite3 hook cache with the exact upstream-hashed release library."""
import hashlib
import json
from pathlib import Path
import re
import shutil
import sys
from urllib.parse import unquote, urljoin, urlparse

os_name, arch = sys.argv[1:]
config_path = Path('.dart_tool/package_config.json').resolve()
config = json.loads(config_path.read_text())
package = next(p for p in config['packages'] if p['name'] == 'sqlite3')
package_uri = urljoin(config_path.as_uri(), package['rootUri'])
package_path = unquote(urlparse(package_uri).path)
if sys.platform == 'win32' and package_path.startswith('/'):
    package_path = package_path[1:]
hashes = (Path(package_path) / 'lib/src/hook/asset_hashes.dart').read_text()
filename = f'libsqlite3.{arch}.linux.so' if os_name == 'linux' else f'sqlite3.{arch}.windows.dll'
match = re.search(r"'" + re.escape(filename) + r"': '([a-f0-9]{64})'", hashes)
if not match:
    raise RuntimeError(f'No pinned upstream hash for {filename}')
expected = match[1]
name = 'libsqlite3.so' if os_name == 'linux' else 'sqlite3.dll'
candidates = list(Path('native-extracted').rglob(name))
verified = [p for p in candidates if hashlib.sha256(p.read_bytes()).hexdigest() == expected]
if not verified:
    raise RuntimeError('Verified package does not contain the exact pinned SQLite binary')
target = Path('.dart_tool/hooks_runner/shared/sqlite3/build') / f'download-{expected[:8]}' / name
target.parent.mkdir(parents=True, exist_ok=True)
shutil.copyfile(verified[0], target)
print(f'Staged upstream-verified {filename}: {expected}')
