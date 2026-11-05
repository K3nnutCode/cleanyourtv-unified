param(
    [Parameter(Mandatory=$true)][string]$Device,
    [ValidateSet('Status','Enable','Restore')][string]$Mode = 'Status',
    [string]$BackupPath,
    [ValidateRange(1,120)][int]$IdleMinutes,
    [string]$AdbPath = 'adb'
)
$ErrorActionPreference = 'Stop'
$component = 'com.k3nnut.cleanyourtv.unified/com.gathin.tvhome.AmbientPhotoDream'
$keys = @('screensaver_components','screensaver_enabled','screensaver_activate_on_sleep')

function Invoke-Tv([string[]]$Arguments) {
    $lines = @(& $AdbPath -s $Device @Arguments 2>&1)
    if ($LASTEXITCODE -ne 0) { throw "TV command failed: $($lines -join ' ')" }
    return ($lines -join "`n").Trim()
}
function Read-Setting([string]$Namespace, [string]$Key) {
    return Invoke-Tv @('shell','settings','get',$Namespace,$Key)
}
function Write-Setting([string]$Namespace, [string]$Key, [string]$Value) {
    # Values become shell arguments; accept only known settings formats, never commands.
    if ($Key -eq 'screensaver_components') {
        if ($Value -ne 'null' -and $Value -notmatch '^[a-zA-Z0-9_./]+(,[a-zA-Z0-9_./]+)*$') {
            throw 'Unsupported previous screensaver component format; no unsafe shell value will be used.'
        }
    } elseif ($Value -ne 'null' -and $Value -notmatch '^-?\d+$') { throw 'Invalid setting value.' }
    if ($Value -eq 'null') { $null = Invoke-Tv @('shell','settings','delete',$Namespace,$Key) }
    else { $null = Invoke-Tv @('shell','settings','put',$Namespace,$Key,$Value) }
    if ((Read-Setting $Namespace $Key) -cne $Value) { throw "TV did not retain $Key; stopped." }
}

if ((Invoke-Tv @('get-state')) -ne 'device') { throw 'Use an already authorised, connected TV.' }
$sdkText = Invoke-Tv @('shell','getprop','ro.build.version.sdk')
if ($sdkText -notmatch '^\d+$' -or [int]$sdkText -lt 26) { throw 'Android API 26 or newer is required.' }
$features = Invoke-Tv @('shell','pm','list','features')
if ($features -notmatch 'android\.(software\.leanback|hardware\.type\.television)') { throw 'TV interface not detected; stop and inspect this device.' }
$maker = Invoke-Tv @('shell','getprop','ro.product.manufacturer')
$model = Invoke-Tv @('shell','getprop','ro.product.model')
$native = Invoke-Tv @('shell','cmd','package','resolve-activity','--brief','-a','android.settings.DREAM_SETTINGS')
$hasNative = $native -match '(?m)^\s*[a-zA-Z0-9_.]+/[a-zA-Z0-9_.]+\s*$'
Write-Output "$maker $model | Android API $sdkText"
Write-Output $(if ($hasNative) { 'Native screensaver picker: available.' } else { 'Native screensaver picker: unavailable. Authorised installer setup can select Unified directly.' })
if ($Mode -eq 'Status') {
    Write-Output ('Selected screensaver: ' + (Read-Setting 'secure' 'screensaver_components'))
    return
}
if (-not $BackupPath) { throw 'BackupPath is required for Enable or Restore.' }
$backupFile = [System.IO.Path]::GetFullPath($BackupPath)

if ($Mode -eq 'Restore') {
    $backup = Get-Content -LiteralPath $backupFile -Raw | ConvertFrom-Json
    if ($backup.version -ne 1 -or $backup.device -cne $Device -or $backup.component -cne $component -or
            $backup.manufacturer -cne $maker -or $backup.model -cne $model) {
        throw 'Recovery file does not match this selected TV and setup format.'
    }
    $settings = @($backup.settings)
    if ($settings.Count -notin @(3,4)) { throw 'Invalid recovery setting count.' }
    $seen = @{}
    foreach ($entry in $settings) {
        $expected = if ($entry.namespace -eq 'secure' -and $entry.key -in $keys) {
            if ($entry.key -eq 'screensaver_components') { $component } else { '1' }
        } elseif ($entry.namespace -eq 'system' -and $entry.key -eq 'screen_off_timeout') {
            if ([string]$entry.applied -notmatch '^\d+$' -or [long]$entry.applied -lt 60000 -or [long]$entry.applied -gt 7200000) { throw 'Invalid recovery timeout.' }
            [string]$entry.applied
        } else { throw 'Unexpected recovery setting.' }
        if ($seen.ContainsKey($entry.key) -or [string]$entry.applied -cne $expected) { throw 'Invalid recovery entry.' }
        $seen[$entry.key] = $true
        if ($entry.key -eq 'screensaver_components') {
            if ([string]$entry.previous -ne 'null' -and [string]$entry.previous -notmatch '^[a-zA-Z0-9_./]+(,[a-zA-Z0-9_./]+)*$') { throw 'Invalid recovery component.' }
        } elseif ([string]$entry.previous -ne 'null' -and [string]$entry.previous -notmatch '^-?\d+$') { throw 'Invalid recovery value.' }
        if ((Read-Setting $entry.namespace $entry.key) -cne [string]$entry.applied) {
            throw 'TV settings changed since setup. Stop rather than overwrite a newer owner choice.'
        }
    }
    foreach ($key in $keys) { if (-not $seen.ContainsKey($key)) { throw 'Incomplete recovery file.' } }
    foreach ($entry in $settings) { Write-Setting $entry.namespace $entry.key ([string]$entry.previous) }
    Write-Output 'Previous screensaver settings restored and verified. Recovery file retained.'
    return
}

$services = Invoke-Tv @('shell','cmd','package','query-services','--brief','-a','android.service.dreams.DreamService')
if ($services -notmatch 'com\.k3nnut\.cleanyourtv\.unified/(com\.gathin\.tvhome\.AmbientPhotoDream|\.AmbientPhotoDream)(\s|$)') {
    throw 'Unified screensaver is not registered/enabled on this TV. No settings changed.'
}
if ((Read-Setting 'secure' 'screensaver_components') -ceq $component -and
        (Read-Setting 'secure' 'screensaver_enabled') -eq '1' -and
        (Read-Setting 'secure' 'screensaver_activate_on_sleep') -eq '1' -and
        (-not $PSBoundParameters.ContainsKey('IdleMinutes') -or (Read-Setting 'system' 'screen_off_timeout') -eq [string]($IdleMinutes * 60000))) {
    Write-Output 'Unified screensaver is already configured. Existing recovery file and settings left unchanged.'
    return
}
if (Test-Path -LiteralPath $backupFile) { throw 'Recovery file already exists. Keep it; choose a new path only for a separately approved setup.' }
$settings = @()
foreach ($key in $keys) {
    $previous = Read-Setting 'secure' $key
    if ($key -eq 'screensaver_components') {
        if ($previous -ne 'null' -and $previous -notmatch '^[a-zA-Z0-9_./]+(,[a-zA-Z0-9_./]+)*$') { throw 'Unsupported previous component format.' }
    } elseif ($previous -ne 'null' -and $previous -notmatch '^-?\d+$') { throw 'Unsupported previous activation value.' }
    $settings += [pscustomobject]@{ namespace='secure'; key=$key; previous=$previous; applied=$(if ($key -eq 'screensaver_components') {$component} else {'1'}) }
}
if ($PSBoundParameters.ContainsKey('IdleMinutes')) {
    $previous = Read-Setting 'system' 'screen_off_timeout'
    if ($previous -ne 'null' -and $previous -notmatch '^-?\d+$') { throw 'Unsupported previous timeout.' }
    $settings += [pscustomobject]@{ namespace='system'; key='screen_off_timeout'; previous=$previous; applied=[string]($IdleMinutes * 60000) }
}
$snapshot = @{ version=1; device=$Device; manufacturer=$maker; model=$model; component=$component; settings=$settings }
$json = $snapshot | ConvertTo-Json -Depth 5
# CreateNew prevents overwriting the first recovery snapshot, even on concurrent runs.
$stream = [System.IO.File]::Open($backupFile, [System.IO.FileMode]::CreateNew)
try { $bytes = [System.Text.UTF8Encoding]::new($false).GetBytes($json); $stream.Write($bytes,0,$bytes.Length); $stream.Flush() }
finally { $stream.Dispose() }
$changed = [System.Collections.Generic.List[object]]::new()
try {
    foreach ($entry in $settings) {
        if ((Read-Setting $entry.namespace $entry.key) -cne $entry.previous) {
            throw 'TV settings changed during setup; refusing to overwrite a newer choice.'
        }
        if ($entry.previous -ceq $entry.applied) { continue }
        # Include a possibly applied write in rollback even when its readback fails.
        $changed.Add($entry)
        Write-Setting $entry.namespace $entry.key $entry.applied
    }
} catch {
    $problem = $_
    $rollbackFailed = $false
    for ($i=$changed.Count-1; $i -ge 0; $i--) {
        $entry = $changed[$i]
        try {
            $current = Read-Setting $entry.namespace $entry.key
            if ($current -ceq $entry.previous) { continue }
            if ($current -cne $entry.applied) { throw 'Setting changed after this setup write.' }
            Write-Setting $entry.namespace $entry.key $entry.previous
        }
        catch { $rollbackFailed=$true; Write-Warning "Could not restore $($entry.key). Keep the recovery file and use Settings/authorised ADB." }
    }
    if (-not $rollbackFailed) { Write-Warning 'Setup failed; previous settings restored and verified.' }
    throw $problem
}
Write-Output 'Unified screensaver selected and settings verified. No manufacturer app was disabled.'
Write-Output 'Upload photos into Unified before testing idle entry. Selection alone is not proof of working idle playback.'
Write-Output "Recovery file saved locally: $backupFile (keep private; includes the selected connection address)."
