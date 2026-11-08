param([Parameter(Mandatory=$true)][ValidateSet('x64','arm64')][string]$Arch)
$ErrorActionPreference = 'Stop'
git diff --exit-code 9553af072d78936efe03ea80e3d3ae69b041d4f8 HEAD -- rust_backend pubspec.yaml pubspec.lock
if ($LASTEXITCODE -ne 0) { throw 'Native source/dependency graph differs from verified build' }
foreach ($line in Get-Content "native-package\SHA256SUMS-windows-$Arch.txt") {
    $expected,$name = $line -split '  ',2
    if ((Get-FileHash -LiteralPath (Join-Path 'native-package' $name) -Algorithm SHA256).Hash -ne $expected) { throw 'Native package checksum mismatch' }
}
Expand-Archive -LiteralPath "native-package\SpotiFLAC-v5.2.6-windows-$Arch-portable.zip" -DestinationPath native-extracted
./scripts/check_windows_bundle.ps1 -BundleDir native-extracted -Arch $Arch -InspectOnly
$rust = "rust_backend\target\desktop\windows\$Arch"
New-Item -ItemType Directory -Force $rust,"build\ffmpeg\windows-$Arch",'native-libmpv' | Out-Null
Copy-Item native-extracted\spotiflac_desktop.dll $rust
Copy-Item native-extracted\ffmpeg\* "build\ffmpeg\windows-$Arch" -Recurse
Copy-Item native-extracted\libmpv-2.dll native-libmpv
"SPOTIFLAC_VERIFIED_LIBMPV=$PWD\native-libmpv" >> $env:GITHUB_ENV
if ($Arch -eq 'x64') {
    New-Item -ItemType Directory -Force native-ffmpegkit\bin | Out-Null
    foreach ($pattern in @('libffmpegkit.dll','av*.dll','sw*.dll','libgcc_s*.dll','libstdc++*.dll','libwinpthread*.dll')) {
        Get-ChildItem native-extracted -Filter $pattern -File | Copy-Item -Destination native-ffmpegkit\bin
    }
    "FFMPEGKIT_LOCAL_DIR=$PWD\native-ffmpegkit" >> $env:GITHUB_ENV
}
Get-FileHash "$rust\spotiflac_desktop.dll",'native-libmpv\libmpv-2.dll',"build\ffmpeg\windows-$Arch\ffmpeg.exe" -Algorithm SHA256
