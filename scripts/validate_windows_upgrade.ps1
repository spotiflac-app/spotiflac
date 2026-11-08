[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)][string]$Directory,
    [Parameter(Mandatory=$true)][ValidateSet('x64','arm64')][string]$Arch,
    [string]$Version='5.2.7',
    [int]$BuildNumber=166
)
$ErrorActionPreference='Stop'
if (-not $env:GITHUB_ACTIONS -or $env:RUNNER_ENVIRONMENT -ne 'github-hosted') { throw 'Upgrade test requires a disposable GitHub-hosted runner' }
$Directory=(Resolve-Path -LiteralPath $Directory).Path
$repo='spotiflac-app/spotiflac-releases'
$previous=gh api "repos/$repo/releases/tags/v5.2.6" | ConvertFrom-Json
if ($LASTEXITCODE -ne 0 -or $previous.draft) { throw 'Previous public release unavailable' }
$asset=$previous.assets | Where-Object name -eq "SpotiFLAC-v5.2.6-windows-$Arch-setup.exe"
if (@($asset).Count -ne 1 -or $asset.digest -notmatch '^sha256:[a-f0-9]{64}$') { throw 'Previous installer has no verified digest' }
$old=Join-Path $Directory 'previous-setup.exe'
Invoke-WebRequest -Uri $asset.browser_download_url -OutFile $old
if ('sha256:'+(Get-FileHash -LiteralPath $old -Algorithm SHA256).Hash.ToLowerInvariant() -ne $asset.digest) { throw 'Previous installer digest mismatch' }
$install=Join-Path $env:RUNNER_TEMP 'spotiflac-upgrade-check'
if (-not ([IO.Path]::GetFullPath($install)).StartsWith(([IO.Path]::GetFullPath($env:RUNNER_TEMP))+'\',[StringComparison]::OrdinalIgnoreCase)) { throw 'Install target escaped runner temp' }
function Install-TestPackage([string]$Path) {
    $p=Start-Process -FilePath $Path -ArgumentList @('/VERYSILENT','/SUPPRESSMSGBOXES','/NORESTART',('/DIR="'+$install+'"')) -WindowStyle Hidden -Wait -PassThru
    if ($p.ExitCode -ne 0) { throw "Installer failed: $($p.ExitCode)" }
}
Install-TestPackage $old
$exe=Join-Path $install 'spotiflac.exe'
if ([Diagnostics.FileVersionInfo]::GetVersionInfo($exe).ProductVersion -ne '5.2.6+165') { throw 'Previous version was not installed' }
$profile=Join-Path $env:APPDATA 'SpotiFLAC\SpotiFLAC'
New-Item -ItemType Directory -Path $profile -Force | Out-Null
$prefs=Join-Path $profile 'shared_preferences.json'
[IO.File]::WriteAllText($prefs,'{"flutter.audit_upgrade_marker":"preserve-existing-settings"}')
$before=(Get-FileHash -LiteralPath $prefs -Algorithm SHA256).Hash
$new=Join-Path $Directory "SpotiFLAC-v$Version-windows-$Arch-setup.exe"
$manifest=Get-Content -LiteralPath (Join-Path $Directory "SHA256SUMS-windows-$Arch.txt")
$line=$manifest | Where-Object { $_.EndsWith('  '+[IO.Path]::GetFileName($new)) }
if (@($line).Count -ne 1 -or (Get-FileHash -LiteralPath $new -Algorithm SHA256).Hash -ne ($line -split '  ',2)[0]) { throw 'New installer digest mismatch' }
Install-TestPackage $new
if ([Diagnostics.FileVersionInfo]::GetVersionInfo($exe).ProductVersion -ne "$Version+$BuildNumber") { throw 'Upgrade did not install expected version' }
if ((Get-FileHash -LiteralPath $prefs -Algorithm SHA256).Hash -ne $before) { throw 'Upgrade changed existing preferences' }
$process=Start-Process -FilePath $exe -WorkingDirectory $install -WindowStyle Hidden -PassThru
try {
    Start-Sleep -Seconds 20
    $process.Refresh()
    if ($process.HasExited) { throw 'Upgraded app exited during startup' }
} finally {
    if (-not $process.HasExited) { Stop-Process -Id $process.Id }
}
@{architecture=$Arch;from='5.2.6+165';to="$Version+$BuildNumber";settings_preserved=$true;startup_20_seconds=$true;passed=$true} | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $Directory 'upgrade-validation.json')
