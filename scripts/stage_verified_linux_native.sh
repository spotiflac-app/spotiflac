#!/usr/bin/env bash
# Reuse immutable native components when only Flutter/Dart branding changed.
set -euo pipefail
ARCH="${1:?x64 or arm64}"
case "$ARCH" in x64) DEB=amd64; MACHINE='Advanced Micro Devices X86-64' ;; arm64) DEB=arm64; MACHINE='AArch64' ;; *) exit 1 ;; esac
BASE=a6f8660daf37e0e71676a12b44ef484150caef72
git diff --exit-code "$BASE" HEAD -- rust_backend pubspec.yaml pubspec.lock scripts/build_linux_ffmpeg.sh scripts/build_linux_smb2.sh
(cd native-package && sha256sum -c SHA256SUMS-linux-*.txt)
dpkg-deb -x "native-package/SpotiFLAC-v5.2.6-linux-$DEB.deb" native-extracted
BUNDLE="$PWD/native-extracted/usr/lib/spotiflac"
readelf -h "$BUNDLE/lib/libspotiflac_desktop.so" | grep -F "$MACHINE"
mkdir -p rust_backend/target/desktop/linux "build/ffmpeg/linux-$ARCH" "build/smb2/linux-$ARCH"
cp "$BUNDLE/lib/libspotiflac_desktop.so" rust_backend/target/desktop/linux/
cp -a "$BUNDLE/lib/ffmpeg/." "build/ffmpeg/linux-$ARCH/"
cp "$BUNDLE/lib/libsmb2.so" "build/smb2/linux-$ARCH/"
cp "$BUNDLE/data/smb2/"*.txt "build/smb2/linux-$ARCH/"
if [[ "$ARCH" == x64 ]]; then
  mkdir -p native-ffmpegkit/lib
  cp -a "$BUNDLE/lib/"libav*.so* "$BUNDLE/lib/"libsw*.so* "$BUNDLE/lib/"libffmpegkit.so* native-ffmpegkit/lib/
  echo "FFMPEGKIT_LOCAL_DIR=$PWD/native-ffmpegkit" >> "$GITHUB_ENV"
fi
# Same mimalloc bytes required by media_kit_libs_linux 1.2.1, fetched
# directly from codeload when GitHub's archive redirect is unhealthy.
mkdir -p "build/linux/$ARCH/release"
curl -fL --retry 3 https://codeload.github.com/microsoft/mimalloc/tar.gz/refs/tags/v2.1.2 -o "build/linux/$ARCH/release/mimalloc-2.1.2.tar.gz"
echo "2b1bff6f717f9725c70bf8d79e4786da13de8a270059e4ba0bdd262ae7be46eb  build/linux/$ARCH/release/mimalloc-2.1.2.tar.gz" | sha256sum -c -
sha256sum rust_backend/target/desktop/linux/libspotiflac_desktop.so "build/smb2/linux-$ARCH/libsmb2.so" "build/ffmpeg/linux-$ARCH/ffmpeg" "build/ffmpeg/linux-$ARCH/ffprobe"
