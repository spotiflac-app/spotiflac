[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$Directory,
    [Parameter(Mandatory = $true)][ValidateSet('x64', 'arm64')][string]$Arch,
    [string]$Version = '5.2.6',
    [int]$BuildNumber = 165
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
if ($Version -notmatch '^\d+\.\d+\.\d+(?:-[0-9A-Za-z.-]+)?$' -or $BuildNumber -le 0) { throw 'Invalid version/build' }
$productVersion = "$Version+$BuildNumber"
$Directory = (Resolve-Path -LiteralPath $Directory).Path
$report = @{ architecture = $Arch; version = $productVersion; passed = $false;
    limits = 'Native startup only; no hardware audio or commercial-provider GUI coverage.' }
$appProcess = $null
try {
    $manifest = Join-Path $Directory "SHA256SUMS-windows-$Arch.txt"
    foreach ($line in Get-Content -LiteralPath $manifest) {
        if (-not $line.Trim()) { continue }
        $pattern = '^([0-9a-fA-F]{64}) [ *](SpotiFLAC-v' + [regex]::Escape($Version) + '-[A-Za-z0-9_.-]+)$'
        if ($line -notmatch $pattern) { throw 'Invalid checksum manifest' }
        $expected = $Matches[1]
        $path = Join-Path $Directory $Matches[2]
        if ((Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash -ne $expected) { throw 'Package checksum mismatch' }
    }
    $archive = Join-Path $Directory "SpotiFLAC-v$Version-windows-$Arch-portable.zip"
    $bundle = Join-Path $Directory 'bundle'
    Expand-Archive -LiteralPath $archive -DestinationPath $bundle
    & "$PSScriptRoot\check_windows_bundle.ps1" -BundleDir $bundle -Arch $Arch
    $executable = Join-Path $bundle 'spotiflac.exe'
    $version = [Diagnostics.FileVersionInfo]::GetVersionInfo($executable)
    if ($version.ProductName -ne 'SpotiFLAC' -or $version.ProductVersion -ne $productVersion) { throw 'Unexpected product version' }
    $report.portable_sha256 = (Get-FileHash -LiteralPath $archive -Algorithm SHA256).Hash.ToLowerInvariant()
    # Disposable hosted runner; no owner's profile, library or credentials.
    $appProcess = Start-Process -FilePath $executable -WorkingDirectory $bundle -WindowStyle Hidden -PassThru `
        -RedirectStandardOutput (Join-Path $Directory 'startup-stdout.log') `
        -RedirectStandardError (Join-Path $Directory 'startup-stderr.log')
    Start-Sleep -Seconds 20
    $appProcess.Refresh()
    if ($appProcess.HasExited) { throw "App exited during startup: $($appProcess.ExitCode)" }
    $report.native_startup_20_seconds = $true
    $report.passed = $true
}
finally {
    if ($null -ne $appProcess -and -not $appProcess.HasExited) {
        # Target only the process started above; never kill by image name.
        Stop-Process -Id $appProcess.Id
    }
    $report | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath (Join-Path $Directory 'validation.json')
}
$report | ConvertTo-Json -Depth 4
