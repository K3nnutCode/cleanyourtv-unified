param([Parameter(Mandatory=$true)][string]$Device,
      [Parameter(Mandatory=$true)][string]$Apk)
$ErrorActionPreference = 'Stop'
$apkPath = (Resolve-Path -LiteralPath $Apk).Path
# Explicit target only. Does not connect, disable, select Home, grant permissions or alter dreams.
& adb -s $Device get-state
if ($LASTEXITCODE -ne 0) { throw 'The selected TV is not already authorised and connected' }
& adb -s $Device install -r $apkPath
if ($LASTEXITCODE -ne 0) { throw 'Installation refused. Keep existing packages; do not bypass verification.' }
& adb -s $Device shell am start -n com.k3nnut.cleanyourtv.unified/com.gathin.tvhome.HomeCandidateActivity
if ($LASTEXITCODE -ne 0) { throw 'Open CleanYourTV Unified from the TV app list' }
