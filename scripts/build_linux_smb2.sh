#!/usr/bin/env bash
# Rebuild dart_smb2 0.1.3's r8 recipe without changing its source or patches.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
case "$(uname -m)" in
  x86_64) TARGET=linux-x64; ARCH=x86_64 ;;
  aarch64) TARGET=linux-arm64; ARCH=aarch64 ;;
  *) echo 'Unsupported native Linux architecture.' >&2; exit 1 ;;
esac
PIN=f0688e739ec56842981e455cf8eba4a34e7682e7
SHA=fb7bae758a18849d0c442a04850668a33f1cd3f70bfdaabc638a768d581a3c5b
WORK="$ROOT/build/smb2/.work"
OUT="$ROOT/build/smb2/$TARGET"
mkdir -p "$WORK" "$OUT"
if [[ ! -f "$WORK/kit.tar.gz" ]]; then
  curl -fL --retry 3 "https://codeload.github.com/ales-drnz/libsmb2-scripts/tar.gz/$PIN" -o "$WORK/kit.tar.gz.part"
  mv "$WORK/kit.tar.gz.part" "$WORK/kit.tar.gz"
fi
echo "$SHA  $WORK/kit.tar.gz" | sha256sum -c -
mkdir -p "$WORK/kit"
tar -xf "$WORK/kit.tar.gz" -C "$WORK/kit" --strip-components=1
# The r8 script ends with `test && cleanup`, which returns 1 when keeping
# sources. Use an explicit conditional so a successful build returns 0.
python3 - "$WORK/kit/scripts/build_libsmb2_linux.sh" <<'PY'
from pathlib import Path
import sys
path = Path(sys.argv[1])
text = path.read_text()
old = '[ "${KEEP_BUILD:-0}" != "1" ] && rm -rf "$BUILD_DIR"'
assert text.count(old) == 1
path.write_text(text.replace(old, 'if [ "${KEEP_BUILD:-0}" != "1" ]; then rm -rf "$BUILD_DIR"; fi'))
PY
if [[ "$ARCH" == aarch64 ]]; then
  # Upstream's old recipe assumes an x64 host for ARM. Use the native GCC.
  sed -i 's/aarch64-linux-gnu-gcc/gcc/g' "$WORK/kit/scripts/build_libsmb2_linux.sh"
fi
ARCHS="$ARCH" KEEP_BUILD=1 bash "$WORK/kit/scripts/build_libsmb2_linux.sh"
install -m755 "$WORK/kit/release_builds/libsmb2_linux-$ARCH.so" "$OUT/libsmb2.so"
cp "$WORK/kit/LICENSE" "$OUT/BUILD-KIT-LICENSE.txt"
cp "$WORK/kit/scripts/build-linux/libsmb2-src/COPYING" "$OUT/LIBSMB2-COPYING.txt"
cp "$WORK/kit/scripts/build-linux/libsmb2-src/LICENCE-LGPL-2.1.txt" "$OUT/LICENCE-LGPL-2.1.txt"
{
  echo "dart_smb2 0.1.3 / libsmb2-r8, build kit $PIN (archive SHA-256 $SHA)."
  echo 'Upstream libsmb2 595d128b4d11a88a335eee961689a157e4f76cd3 with the r8 patch set.'
  echo 'Source and patches: https://github.com/ales-drnz/libsmb2-scripts/tree/'"$PIN"
  echo "Compiler: $(gcc --version | head -1)"
  echo "libc: $(getconf GNU_LIBC_VERSION)"
} > "$OUT/SOURCE.txt"
