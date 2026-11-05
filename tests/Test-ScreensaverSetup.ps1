param([Parameter(Mandatory=$true)][string]$WorkingDirectory)
$ErrorActionPreference='Stop'
$root=[System.IO.Path]::GetFullPath($WorkingDirectory)
$null=New-Item -ItemType Directory -Force -Path $root
$fake=Join-Path $root 'fake-adb.ps1'
$state=Join-Path $root 'state.json'
$backup=Join-Path $root 'recovery.json'
$setup=Join-Path $PSScriptRoot '../Set-Screensaver.ps1'
$originalEnv=$env:CYTV_TEST_STATE
$env:CYTV_TEST_STATE=$state
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
    '^shell cmd package resolve-activity' { 'No activity found'; return }
    '^shell cmd package query-services' { if ($state.registered) { 'com.k3nnut.cleanyourtv.unified/com.gathin.tvhome.AmbientPhotoDream' }; return }
    '^shell settings get ' { $value=$state.values.($a[4]); if ($null -eq $value) {'null'} else {$value}; return }
    '^shell settings (put|delete) ' {
        $key=$a[4]
        if ($state.failOnce -eq $key) {
            $state.failOnce=''; $state | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $env:CYTV_TEST_STATE
            $global:LASTEXITCODE=1; 'Permission denied by simulated TV'; return
        }
        $state.writes++
        $state.values.$key=$(if ($a[2] -eq 'delete') {'null'} else {[string]$a[5]})
        $state | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $env:CYTV_TEST_STATE
        return
    }
    default { throw "Unexpected fake command: $command" }
}
'@ | Set-Content -LiteralPath $fake
function Reset-State {
    @{ api='30'; registered=$true; writes=0; failOnce=''; values=@{
        screensaver_components='com.example.previous/.PhotoDream'; screensaver_enabled='0';
        screensaver_activate_on_sleep='0'; screen_off_timeout='600000'
    }} | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $state
    if (Test-Path -LiteralPath $backup) { Remove-Item -LiteralPath $backup }
}
function Read-State { Get-Content -LiteralPath $state -Raw | ConvertFrom-Json }
function Assert($Condition,[string]$Message) { if (-not $Condition) { throw $Message } }
function Expect-Failure([scriptblock]$Action,[string]$Pattern) {
    $caught=$null
    try { & $Action | Out-Null } catch { $caught=$_ }
    Assert ($null -ne $caught -and $caught.ToString() -match $Pattern) "Expected failure matching $Pattern; got $caught"
}
try {
    Reset-State
    & $setup -Device 'test-tv' -Mode Status -AdbPath $fake | Out-Null
    Assert ((Read-State).writes -eq 0) 'Status mutated settings.'
    Assert (-not (Test-Path -LiteralPath $backup)) 'Status created recovery data.'

    & $setup -Device 'test-tv' -Mode Enable -BackupPath $backup -IdleMinutes 5 -AdbPath $fake | Out-Null
    $enabled=Read-State
    Assert ($enabled.values.screensaver_components -eq 'com.k3nnut.cleanyourtv.unified/com.gathin.tvhome.AmbientPhotoDream') 'Enable selected wrong component.'
    Assert ($enabled.values.screen_off_timeout -eq '300000') 'Enable did not set timeout.'
    $beforeHash=(Get-FileHash -LiteralPath $backup).Hash
    & $setup -Device 'test-tv' -Mode Enable -BackupPath $backup -IdleMinutes 5 -AdbPath $fake | Out-Null
    Assert ((Read-State).writes -eq $enabled.writes) 'Repeat setup was not idempotent.'
    Assert ((Get-FileHash -LiteralPath $backup).Hash -eq $beforeHash) 'Repeat setup replaced recovery snapshot.'

    & $setup -Device 'test-tv' -Mode Restore -BackupPath $backup -AdbPath $fake | Out-Null
    $restored=Read-State
    Assert ($restored.values.screensaver_components -eq 'com.example.previous/.PhotoDream' -and $restored.values.screensaver_enabled -eq '0' -and $restored.values.screensaver_activate_on_sleep -eq '0' -and $restored.values.screen_off_timeout -eq '600000') 'Restore did not recover exact previous choices.'
    Expect-Failure { & $setup -Device 'test-tv' -Mode Enable -BackupPath $backup -AdbPath $fake } 'already exists'
    Assert ((Read-State).writes -eq $restored.writes) 'Existing recovery snapshot did not block mutation.'

    Reset-State
    $s=Read-State; $s.failOnce='screensaver_activate_on_sleep'; $s | ConvertTo-Json -Depth 5 | Set-Content $state
    Expect-Failure { & $setup -Device 'test-tv' -Mode Enable -BackupPath $backup -AdbPath $fake } 'Permission denied'
    $rolledBack=Read-State
    Assert ($rolledBack.values.screensaver_components -eq 'com.example.previous/.PhotoDream' -and $rolledBack.values.screensaver_enabled -eq '0' -and $rolledBack.values.screensaver_activate_on_sleep -eq '0') 'Refused setting left partial configuration.'

    Reset-State
    & $setup -Device 'test-tv' -Mode Enable -BackupPath $backup -AdbPath $fake | Out-Null
    $s=Read-State; $s.values.screensaver_components='com.example.newchoice/.Dream'; $s | ConvertTo-Json -Depth 5 | Set-Content $state
    $writes=$s.writes
    Expect-Failure { & $setup -Device 'test-tv' -Mode Restore -BackupPath $backup -AdbPath $fake } 'newer owner choice'
    Assert ((Read-State).writes -eq $writes) 'Restore overwrote a newer owner choice.'
    Expect-Failure { & $setup -Device 'different-tv' -Mode Restore -BackupPath $backup -AdbPath $fake } 'does not match'

    Reset-State
    $s=Read-State; $s.api='25'; $s | ConvertTo-Json -Depth 5 | Set-Content $state
    Expect-Failure { & $setup -Device 'test-tv' -Mode Enable -BackupPath $backup -AdbPath $fake } 'API 26'
    Assert ((Read-State).writes -eq 0) 'Unsupported API mutated settings.'
    Reset-State
    $s=Read-State; $s.registered=$false; $s | ConvertTo-Json -Depth 5 | Set-Content $state
    Expect-Failure { & $setup -Device 'test-tv' -Mode Enable -BackupPath $backup -AdbPath $fake } 'not registered'
    Assert ((Read-State).writes -eq 0) 'Missing service mutated settings.'

    Reset-State
    $s=Read-State; $s.values.screensaver_components='null'; $s.values.screensaver_enabled='null'; $s | ConvertTo-Json -Depth 5 | Set-Content $state
    & $setup -Device 'test-tv' -Mode Enable -BackupPath $backup -AdbPath $fake | Out-Null
    & $setup -Device 'test-tv' -Mode Restore -BackupPath $backup -AdbPath $fake | Out-Null
    Assert ((Read-State).values.screensaver_components -eq 'null' -and (Read-State).values.screensaver_enabled -eq 'null') 'Absent original settings were not restored as absent.'

    Reset-State
    & $setup -Device 'test-tv' -Mode Enable -BackupPath $backup -AdbPath $fake | Out-Null
    $tampered=Get-Content $backup -Raw | ConvertFrom-Json
    $tampered.settings[0].previous='com.bad/.Dream;reboot'
    $tampered | ConvertTo-Json -Depth 5 | Set-Content $backup
    $writes=(Read-State).writes
    Expect-Failure { & $setup -Device 'test-tv' -Mode Restore -BackupPath $backup -AdbPath $fake } 'Invalid recovery component'
    Assert ((Read-State).writes -eq $writes) 'Unsafe recovery value reached the TV.'
    'PASS: status, selection, timeout, idempotency, backup protection, exact/absent-setting restore, refused-write rollback, owner-choice protection, device binding, old API, absent service and tampered recovery rejection.'
} finally { $env:CYTV_TEST_STATE=$originalEnv }
