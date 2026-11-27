param([Parameter(Mandatory=$true)][string]$WorkingDirectory)
# Simulated install checks for Install-Test.ps1 on macOS/Linux (CI runs on Ubuntu).
# Fake build-tools are shell scripts, so this suite does not run on Windows.
$ErrorActionPreference='Stop'
if ([System.Environment]::OSVersion.Platform -eq [System.PlatformID]::Win32NT) {
    'SKIP: Test-Install.ps1 uses shell-script build-tools and runs on macOS/Linux only.'; return
}
$root=[System.IO.Path]::GetFullPath($WorkingDirectory)
if (Test-Path -LiteralPath $root) { Remove-Item -LiteralPath $root -Recurse -Force }
$null=New-Item -ItemType Directory -Force -Path $root
$sdk=Join-Path $root 'sdk'
$tools=Join-Path $sdk 'build-tools/34.0.0'
$null=New-Item -ItemType Directory -Force -Path $tools
$emptySdk=Join-Path $root 'empty-sdk'
$null=New-Item -ItemType Directory -Force -Path $emptySdk
$installer=Join-Path $PSScriptRoot '../Install-Test.ps1'
$state=Join-Path $root 'state.json'
$fakeAdb=Join-Path $root 'fake-adb.ps1'
$originalEnv=$env:CYTV_TEST_STATE
$env:CYTV_TEST_STATE=$state

# A simulated APK is a text file: line 1 package name, line 2 signer digest.
@'
#!/bin/sh
f="$3"
echo "package: name='$(sed -n 1p "$f")' versionCode='1' versionName='1.0.0-alpha01-debug'"
echo "sdkVersion:'26'"
'@ | Set-Content -LiteralPath (Join-Path $tools 'aapt')
@'
#!/bin/sh
for a; do f="$a"; done
echo "Signer #1 certificate SHA-256 digest: $(sed -n 2p "$f")"
'@ | Set-Content -LiteralPath (Join-Path $tools 'apksigner')
& chmod +x (Join-Path $tools 'aapt') (Join-Path $tools 'apksigner')

@'
$global:LASTEXITCODE=0
$state=Get-Content -LiteralPath $env:CYTV_TEST_STATE -Raw | ConvertFrom-Json
$a=@($args)[2..($args.Count-1)]
$command=$a -join ' '
switch -Regex ($command) {
    '^get-state$' { 'device'; return }
    '^shell getprop ro.build.version.sdk$' { $state.api; return }
    '^shell getprop ro.product.manufacturer$' { 'TCL'; return }
    '^shell getprop ro.product.model$' { 'Simulated TV'; return }
    '^shell pm list features$' { 'feature:android.software.leanback'; return }
    '^shell pm path com\.k3nnut\.cleanyourtv\.unified$' { if ($state.installed) { 'package:/data/app/unified/base.apk' }; return }
    '^pull /data/app/unified/base\.apk ' { Copy-Item -LiteralPath $state.installed -Destination $a[2]; return }
    '^install -r ' {
        $copy=Join-Path (Split-Path -Parent $env:CYTV_TEST_STATE) 'installed.apk'
        Copy-Item -LiteralPath $a[2] -Destination $copy
        $state.installed=$copy; $state.installs++
        $state | ConvertTo-Json | Set-Content -LiteralPath $env:CYTV_TEST_STATE
        'Success'; return
    }
    '^shell am start ' { 'Starting'; return }
    default { throw "Unexpected fake command: $command" }
}
'@ | Set-Content -LiteralPath $fakeAdb

function New-Apk([string]$Name,[string]$Package,[string]$Signer) {
    $path=Join-Path $root $Name
    "$Package`n$Signer" | Set-Content -LiteralPath $path
    return $path
}
function Reset-State([string]$Api='30') { @{ api=$Api; installed=''; installs=0 } | ConvertTo-Json | Set-Content -LiteralPath $state }
function Read-State { Get-Content -LiteralPath $state -Raw | ConvertFrom-Json }
function Assert($Condition,[string]$Message) { if (-not $Condition) { throw $Message } }
function Expect-Failure([scriptblock]$Action,[string]$Pattern) {
    $caught=$null
    try { & $Action | Out-Null } catch { $caught=$_ }
    Assert ($null -ne $caught -and $caught.ToString() -match $Pattern) "Expected failure matching $Pattern; got $caught"
}

$signerA='a'*64
$signerB='b'*64
$apkA=New-Apk 'unified-a.apk' 'com.k3nnut.cleanyourtv.unified' $signerA
$apkA2=New-Apk 'unified-a2.apk' 'com.k3nnut.cleanyourtv.unified' $signerA
$apkB=New-Apk 'unified-b.apk' 'com.k3nnut.cleanyourtv.unified' $signerB
$other=New-Apk 'other.apk' 'com.example.other' $signerA
try {
    Reset-State
    Expect-Failure { & $installer -Device 'test-tv' -Apk $apkA -SdkRoot $emptySdk -AdbPath $fakeAdb } "build-tools 34\.0\.0 are required: .*aapt was not found"
    Assert ((Read-State).installs -eq 0) 'Missing build-tools still installed.'

    Expect-Failure { & $installer -Device 'test-tv' -Apk $other -SdkRoot $sdk -AdbPath $fakeAdb } 'Only a verified Unified APK'
    Assert ((Read-State).installs -eq 0) 'Foreign package was installed.'

    Reset-State '25'
    Expect-Failure { & $installer -Device 'test-tv' -Apk $apkA -SdkRoot $sdk -AdbPath $fakeAdb } 'does not meet this APK minimum'
    Assert ((Read-State).installs -eq 0) 'Old-API TV received an install.'

    Reset-State
    & $installer -Device 'test-tv' -Apk $apkA -SdkRoot $sdk -AdbPath $fakeAdb | Out-Null
    Assert ((Read-State).installs -eq 1) 'Fresh install did not happen.'

    & $installer -Device 'test-tv' -Apk $apkA2 -SdkRoot $sdk -AdbPath $fakeAdb | Out-Null
    Assert ((Read-State).installs -eq 2) 'Same-signer update did not install.'

    $before=Get-Content -LiteralPath (Read-State).installed -Raw
    Expect-Failure { & $installer -Device 'test-tv' -Apk $apkB -SdkRoot $sdk -AdbPath $fakeAdb } 'Signature mismatch'
    Assert ((Read-State).installs -eq 2) 'Different-signer APK was installed over existing data.'
    Assert ((Get-Content -LiteralPath (Read-State).installed -Raw) -eq $before) 'Existing installation changed after signer mismatch.'

    'PASS: missing build-tools, foreign package, old API, fresh install, same-signer update and signer-mismatch protection.'
} finally { $env:CYTV_TEST_STATE=$originalEnv }
