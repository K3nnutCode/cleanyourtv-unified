param([Parameter(Mandatory=$true)][string]$Device,
      [Parameter(Mandatory=$true)][string]$Apk,
      [string]$SdkRoot = $env:ANDROID_HOME,
      [switch]$ConfigureScreensaver,
      [string]$ScreensaverBackupPath,
      [ValidateRange(1,120)][int]$IdleMinutes)
$ErrorActionPreference = 'Stop'
$apkPath = (Resolve-Path -LiteralPath $Apk).Path
# Explicit target only. Never connects, disables packages, selects Home or grants permissions.
if ($ConfigureScreensaver -and -not $ScreensaverBackupPath) {
    throw 'ScreensaverBackupPath is required with ConfigureScreensaver.'
}
if (-not $ConfigureScreensaver -and $PSBoundParameters.ContainsKey('IdleMinutes')) { throw 'IdleMinutes requires ConfigureScreensaver.' }
if (-not $SdkRoot) { throw 'Set ANDROID_HOME or pass SdkRoot so APK identity/signatures can be verified.' }
$tools = Join-Path $SdkRoot 'build-tools/34.0.0'
$aapt = Join-Path $tools 'aapt.exe'
$signer = Join-Path $tools 'apksigner.bat'
if (-not (Test-Path -LiteralPath $aapt) -or -not (Test-Path -LiteralPath $signer)) { throw 'Android build-tools 34.0.0 are required.' }
function Get-Signer([string]$Path) {
    $report = @(& $signer verify --print-certs $Path 2>&1)
    if ($LASTEXITCODE -ne 0) { throw 'APK signature verification failed.' }
    $certs = @($report | Select-String '^Signer #\d+ certificate SHA-256 digest: ([a-fA-F0-9]{64})$')
    if ($certs.Count -ne 1) { throw 'Expected exactly one verified APK signer.' }
    return $certs[0].Matches[0].Groups[1].Value.ToLowerInvariant()
}
$badging = @(& $aapt dump badging $apkPath)
if ($LASTEXITCODE -ne 0 -or ($badging -join "`n") -notmatch "(?m)^package: name='com.k3nnut.cleanyourtv.unified' ") { throw 'Only a verified Unified APK can be installed.' }
$minimum = [regex]::Match(($badging -join "`n"), "(?m)^sdkVersion:'(\d+)'")
if (-not $minimum.Success -or [int]$minimum.Groups[1].Value -lt 26) { throw 'APK must retain the API 26 minimum.' }
$candidateSigner = Get-Signer $apkPath
& adb -s $Device get-state
if ($LASTEXITCODE -ne 0) { throw 'The selected TV is not already authorised and connected' }
$api = (& adb -s $Device shell getprop ro.build.version.sdk | Out-String).Trim()
if ($LASTEXITCODE -ne 0 -or $api -notmatch '^\d+$' -or [int]$api -lt [int]$minimum.Groups[1].Value) { throw 'TV Android version does not meet this APK minimum.' }
$features = (& adb -s $Device shell pm list features | Out-String)
if ($LASTEXITCODE -ne 0 -or $features -notmatch 'android\.(software\.leanback|hardware\.type\.television)') { throw 'TV interface not detected.' }
$maker = (& adb -s $Device shell getprop ro.product.manufacturer | Out-String).Trim()
$model = (& adb -s $Device shell getprop ro.product.model | Out-String).Trim()
Write-Output "$maker $model | API $api | com.k3nnut.cleanyourtv.unified"
Write-Output "APK SHA-256: $((Get-FileHash -LiteralPath $apkPath -Algorithm SHA256).Hash)"
Write-Output "Verified signer SHA-256: $candidateSigner"
$installed = @(& adb -s $Device shell pm path com.k3nnut.cleanyourtv.unified)
if ($LASTEXITCODE -ne 0) { throw 'Could not inspect existing Unified installation.' }
if ($installed.Count -gt 0) {
    if ($installed.Count -ne 1 -or $installed[0] -notmatch '^package:(/[^\s]+\.apk)$') { throw 'Unsupported existing APK layout; inspect manually.' }
    $installedPath = $Matches[1]
    $auditDir = Join-Path ([System.IO.Path]::GetTempPath()) ('cytv-signature-' + [guid]::NewGuid().ToString('N'))
    $null = New-Item -ItemType Directory -Path $auditDir
    $installedCopy = Join-Path $auditDir 'installed.apk'
    try {
        & adb -s $Device pull $installedPath $installedCopy
        if ($LASTEXITCODE -ne 0) { throw 'Could not retrieve installed APK to check its signer.' }
        if ((Get-Signer $installedCopy) -cne $candidateSigner) { throw 'Signature mismatch. Keep the existing app/photos; use its original signing key. No data will be deleted.' }
    } finally {
        if (Test-Path -LiteralPath $installedCopy) { Remove-Item -LiteralPath $installedCopy }
        Remove-Item -LiteralPath $auditDir
    }
}
& adb -s $Device install -r $apkPath
if ($LASTEXITCODE -ne 0) { throw 'Installation refused. Keep existing packages; do not bypass verification.' }
if ($ConfigureScreensaver) {
    $setup = @{ Device=$Device; Mode='Enable'; BackupPath=$ScreensaverBackupPath }
    if ($PSBoundParameters.ContainsKey('IdleMinutes')) { $setup.IdleMinutes = $IdleMinutes }
    & (Join-Path $PSScriptRoot 'Set-Screensaver.ps1') @setup
}
& adb -s $Device shell am start -n com.k3nnut.cleanyourtv.unified/com.gathin.tvhome.HomeCandidateActivity
if ($LASTEXITCODE -ne 0) { throw 'Open CleanYourTV Unified from the TV app list' }
