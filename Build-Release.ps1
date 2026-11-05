param([Parameter(Mandatory=$true)][string]$SdkRoot,
      [string]$Destination = (Join-Path $PSScriptRoot 'dist'))
$ErrorActionPreference = 'Stop'
$Destination = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Destination)
foreach ($name in 'CYTV_KEYSTORE','CYTV_STORE_PASSWORD','CYTV_KEY_ALIAS','CYTV_KEY_PASSWORD') {
    if (-not [Environment]::GetEnvironmentVariable($name)) { throw "Missing signing input: $name" }
}
if (-not (Test-Path -LiteralPath $env:CYTV_KEYSTORE -PathType Leaf)) { throw 'Keystore does not exist' }
$sdk = (Resolve-Path -LiteralPath $SdkRoot).Path
$env:ANDROID_HOME = $sdk
$signer = Join-Path $sdk 'build-tools/34.0.0/apksigner.bat'
Push-Location $PSScriptRoot
try {
    & ./gradlew.bat --no-daemon clean testReleaseUnitTest lintRelease assembleRelease
    if ($LASTEXITCODE -ne 0) { throw 'Release checks failed; nothing is ready to distribute' }
    $apk = Join-Path $PSScriptRoot 'app/build/outputs/apk/release/app-release.apk'
    $signatureReport = & $signer verify --verbose --print-certs $apk
    if ($LASTEXITCODE -ne 0) { throw 'APK signature verification failed' }
    if (($signatureReport -join "`n") -match 'CN=Android Debug') { throw 'Debug certificate is forbidden for distribution' }
    $signatureReport | Write-Output
    New-Item -ItemType Directory -Force -Path $Destination | Out-Null
    $published = Join-Path $Destination 'CleanYourTV-Unified-1.0.0-alpha01.apk'
    Copy-Item -LiteralPath $apk -Destination $published
    $hash = (Get-FileHash -LiteralPath $published -Algorithm SHA256).Hash.ToLower()
    [IO.File]::WriteAllText((Join-Path $Destination 'SHA256SUMS.txt'), "$hash  $([IO.Path]::GetFileName($published))`n")
    Write-Output "Verified signed alpha created: $published. Publishing requires separate approval."
} finally { Pop-Location }
