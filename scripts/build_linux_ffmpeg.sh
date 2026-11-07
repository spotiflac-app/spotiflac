#!/usr/bin/env bash
# Build LGPL desktop tools against the release runner's glibc. Do not use
# static glibc archives: their resolver can import GLIBC_PRIVATE symbols.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TARGET="${1:?Usage: build_linux_ffmpeg.sh linux-<x64|arm64>}"
case "$(uname -m):$TARGET" in
  x86_64:linux-x64|aarch64:linux-arm64) ;;
  *) echo 'Build Linux FFmpeg on its native architecture.' >&2; exit 1 ;;
esac
OUT="$ROOT/build/ffmpeg/$TARGET"
WORK="$ROOT/build/ffmpeg/.work/$TARGET-source"
DOWNLOADS="$ROOT/build/ffmpeg/.work/downloads"
PREFIX="$WORK/deps"
JOBS="${SPOTIFLAC_BUILD_JOBS:-$(nproc)}"
mkdir -p "$OUT" "$WORK" "$DOWNLOADS" "$PREFIX"
fetch() {
  local name="$1" url="$2" sha="$3"
  if [[ ! -f "$DOWNLOADS/$name" ]]; then
    curl -fL --retry 3 --retry-all-errors "$url" -o "$DOWNLOADS/$name.part"
    mv "$DOWNLOADS/$name.part" "$DOWNLOADS/$name"
  fi
  echo "$sha  $DOWNLOADS/$name" | sha256sum -c -
}
# Same source releases as the existing macOS desktop tools.
fetch ffmpeg-9.0.2.tar.xz https://ffmpeg.org/releases/ffmpeg-9.0.2.tar.xz 8c3850283eb25fa026482078a04051e0be17347b09ef81a0849bec15a96e002e
fetch lame-3.100.tar.gz https://downloads.sourceforge.net/project/lame/lame/3.100/lame-3.100.tar.gz ddfe36cab873794038ae2c1210557ad34857a4b6bdc515785d1da9e175b1da1e
fetch opus-1.5.2.tar.gz https://downloads.xiph.org/releases/opus/opus-1.5.2.tar.gz 65c1d2f78b9f2fb20082c38cbe47c951ad5839345876e46941612ee87f9a7ce1
fetch soxr-0.1.3.tar.xz https://downloads.sourceforge.net/project/soxr/soxr-0.1.3-Source.tar.xz b111c15fdc8c029989330ff559184198c161100a59312f5dc19ddeb9b5a15889
for archive in ffmpeg-9.0.2.tar.xz lame-3.100.tar.gz opus-1.5.2.tar.gz soxr-0.1.3.tar.xz; do
  tar -xf "$DOWNLOADS/$archive" -C "$WORK"
done
export PKG_CONFIG_PATH="$PREFIX/lib/pkgconfig"
export CFLAGS="-O2 -fPIC"
(
  cd "$WORK/lame-3.100"
  ./configure --prefix="$PREFIX" --disable-shared --enable-static --disable-frontend --disable-decoder
  make -j"$JOBS"
  make install
)
(
  cd "$WORK/opus-1.5.2"
  ./configure --prefix="$PREFIX" --disable-shared --enable-static --disable-doc --disable-extra-programs
  make -j"$JOBS"
  make install
)
cmake -S "$WORK/soxr-0.1.3-Source" -B "$WORK/soxr-build" \
  -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX="$PREFIX" \
  -DBUILD_SHARED_LIBS=OFF -DBUILD_TESTS=OFF -DBUILD_EXAMPLES=OFF \
  -DWITH_OPENMP=OFF -DWITH_LSR_BINDINGS=OFF -DCMAKE_POSITION_INDEPENDENT_CODE=ON
cmake --build "$WORK/soxr-build" -j "$JOBS"
cmake --install "$WORK/soxr-build"
OPTIONS=(
  --prefix="$PREFIX" --disable-gpl --disable-nonfree --disable-version3
  --disable-shared --enable-static --disable-autodetect
  --disable-doc --disable-ffplay --disable-debug
  --enable-zlib --enable-gnutls --enable-libmp3lame --enable-libopus --enable-libsoxr
  --extra-cflags="-I$PREFIX/include" --extra-ldflags="-L$PREFIX/lib"
  --extra-libs=-lm
)
(
  cd "$WORK/ffmpeg-9.0.2"
  if ! ./configure "${OPTIONS[@]}"; then
    tail -80 ffbuild/config.log >&2
    exit 1
  fi
  make -j"$JOBS" ffmpeg ffprobe
)
install -m755 "$WORK/ffmpeg-9.0.2/ffmpeg" "$WORK/ffmpeg-9.0.2/ffprobe" "$OUT/"
cp "$WORK/ffmpeg-9.0.2/COPYING.LGPLv2.1" "$OUT/LICENSE.txt"
mkdir -p "$OUT/licenses"
cp "$WORK/lame-3.100/COPYING" "$OUT/licenses/LAME-COPYING.txt"
cp "$WORK/opus-1.5.2/COPYING" "$OUT/licenses/OPUS-COPYING.txt"
cp "$WORK/soxr-0.1.3-Source/LICENCE" "$OUT/licenses/SOXR-LICENCE.txt"
{
  echo 'FFmpeg 9.0.2 LGPL build on the Linux release baseline (dynamic system glibc and GnuTLS).'
  echo 'Recipe: scripts/build_linux_ffmpeg.sh; all source URLs and SHA-256 pins are in that script.'
  printf 'Configure: %q ' "${OPTIONS[@]}"; printf '\n'
  echo "Compiler: $(gcc --version | head -1)"
  echo "libc: $(getconf GNU_LIBC_VERSION)"
} > "$OUT/SOURCE.txt"
"$OUT/ffmpeg" -hide_banner -version
