# Start here — CleanYourTV Unified alpha

For Android TV 8/API 26 and newer. Tested on one TCL Android 11 set; other TV
models/firmware are not certified. This is a debug evaluation build, not a stable
release. No account or cloud photo service is needed by the TV app.

## Easiest route: use an installation agent

Open TRY_WITH_AGENT.md and copy its installation request into your agent.
Stay available to approve your TV's normal debugging prompt and test the remote.
Give the agent your intended TV connection address or USB connection; it must
not scan your network. The agent should inspect the scripts before running them.

## What to have ready

- A Windows computer with PowerShell 7, JDK 17, Android platform-tools (`adb`)
  and Android SDK build-tools 34.0.0. A source build also needs platform 34.
- An authorised connection to the intended TV. List with `adb devices -l`;
  identify the model and stop if it is not your intended TV. If several TVs are
  connected, explicitly select one. Never bypass the normal TV prompt.
- Original copies of your photos and a trusted home network for local upload.
- Access to the physical Settings button or another working Settings route.
  Keep the manufacturer launcher enabled and note the previous Home/screensaver.

Use PowerShell 7 for the commands below. If local policy blocks scripts, stop
and follow your computer's normal policy; these instructions do not require
disabling security controls or changing global execution policy.

## Verify the download before installing

Download `cleanyourtv-unified-preview` from a successful **Build preview APK**
run for the intended source revision, and extract it into a new folder.
`SOURCE-COMMIT.txt` records that revision; `BUILD-RUN.txt` links the actual run.
Check both against GitHub. Older artifacts lack these files and may predate
installer/onboarding updates. Artifacts expire 30 days after their build.

SHA256SUMS.txt covers the APK, setup scripts and guides. Recalculate each listed
file's SHA-256 and compare; do not run a script or APK with a mismatch. The
installer also verifies APK identity/signature and an existing installation's
signer. A checksum alone does not establish who signed an APK. Consult
APK-Signature.txt and the expected build source; there is no permanent production
signing identity yet. A new CI debug signer may not update an older preview.

## Install and add photos

Set ANDROID_HOME to the SDK containing build-tools 34.0.0, or pass `-SdkRoot`.
In the extracted folder, after reviewing the scripts, run:

```powershell
./Install-Test.ps1 -Device '<authorised target>' -Apk './CleanYourTV-Unified-1.0.0-alpha01-debug.apk'
```

If the installer reports a signer mismatch, stop. Keep the existing app/data and
use its original signing key/build; do not uninstall or clear photos to force an
update. Installation does not choose a default Home or screensaver.

In onboarding, open **photo gallery / QR upload** and upload your own originals.
This is temporary authenticated **unencrypted local HTTP** on your trusted home
network. Keep the uploader open while sending; close it when finished. Photos
from older Ambient-preview apps remain private to those apps and are not copied.

## Select the screensaver with less manual setup

After you approve selecting Unified, the installer can handle TVs whose Ambient
menu omits third-party screensavers. No reinstall or manual picker is needed:

```powershell
./Set-Screensaver.ps1 -Device '<authorised target>' -Mode Enable -BackupPath '../my-tv.screensaver-recovery.json'
```

Keep that recovery file private and safe. The previous settings are saved before
changes and every write is checked. The existing timer is preserved. Add
`-IdleMinutes 5` only if you approve a five-minute timeout. Stop if firmware
refuses a change; do not disable vendor packages or grant broad permissions.

For future installs, Install-Test.ps1 also accepts `-ConfigureScreensaver` and
`-ScreensaverBackupPath` to perform both operations in one approved command.
Upload photos during onboarding before waiting for the screensaver to run.
APK-only installation without an authorised computer still requires a supported
native picker; this flow does not remove Android's permission restrictions.

## Check it and recover

Test D-pad, OK, Back, Home, Settings, launching apps and HDMI switching with the
actual remote. Leave the TV idle for its configured timeout, check photos appear,
and press Back to return. Video playback may keep the TV awake. Do not call a
successful setting write a successful idle test.

To restore the previous screensaver settings on the same TV connection:

```powershell
./Set-Screensaver.ps1 -Device '<authorised target>' -Mode Restore -BackupPath '../my-tv.screensaver-recovery.json'
```

Restore stops if settings have since changed, to preserve newer choices. For
Home recovery, choose the previous Home in normal TV Settings. If necessary:

```powershell
adb -s '<authorised target>' shell am start -a android.settings.SETTINGS
```

Keep original photos; clearing Unified data or uninstalling it removes its private
copies. Turn debugging off normally after testing and recovery are verified.
See VERIFICATION.md for actual evidence and remaining checks. Production signing
and prayer-timetable redistribution clearance remain outstanding in NOTICE.md.
