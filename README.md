# CleanYourTV Unified — 1.0.0-alpha01

An implemented integration for evaluation, package `com.k3nnut.cleanyourtv.unified`,
Android 8/API 26 minimum, target/compile API 34. This standalone Gradle project derives from the proven Home and Concept B branches.
It uses a new package ID and leaves the deployed Xiaomi packages untouched.
It retains the v8.3.1 Home activity, four-tile dock, app library, D-pad handling
and upstream input picker, and integrates the v6.3.1 photo gallery, QR uploader,
slideshow and `AmbientPhotoDream` in one application.

## Repository status

Evaluation alpha. Installation and Home were exercised on one TCL Smart TV,
Android 11/API 30; the owner confirmed photo upload works. A later approved
installer-assisted setup selected Unified's own screensaver, which automatically
entered after five minutes and displayed its uploaded photos. Public-release
gates and attribution requirements are recorded below and in NOTICE.md.

## Try with Codex or Claude Code

Start with [QUICK_START.md](QUICK_START.md), or use the ready-to-copy installation
request in [TRY_WITH_AGENT.md](TRY_WITH_AGENT.md). **Build preview APK** validates
pull requests and main updates; main/manual runs produce a clearly labelled debug
testing bundle with the installer, recovery script, guides, source revision and
checksums. No production release is automatic.

## Build and try

Use PowerShell 7, JDK 17, Android platform-tools, SDK platform 34 and build-tools
34.0.0. Set `ANDROID_HOME` to the SDK root. A source build can alternatively use an
ignored `local.properties` with `sdk.dir`; in that case pass the same SDK path to
Install-Test.ps1 using `-SdkRoot`. In this directory run:

```powershell
./gradlew.bat --no-daemon testDebugUnitTest lintDebug assembleDebug
./Install-Test.ps1 -Device '<authorised ADB target>' -Apk './app/build/outputs/apk/debug/app-debug.apk'
```

The supplied debug APK is for evaluation. Its package ID is stable, but a later
production certificate cannot replace this debug signature in place. Export or
retain original photos before clearing app data or replacing a test build.
Never distribute a debug build as the official public release.

The first opening presents setup and capability detection. Finish to see Home.
Hold OK on the Home settings button to reopen **Unified setup & compatibility**
or **Manage screensaver photos**. Add photos in the gallery; choose the photo
screensaver through native settings. Manufacturer restrictions may prevent
default Home or Dream selection. No manufacturer package is disabled and no
default Home or secure screensaver setting is changed by this application.

### Faster screensaver setup, including TCL Ambient-only menus

Some TVs register Unified's DreamService but expose no standard screensaver
picker. On the tested TCL Android 11 set, the DreamService was registered while
`android.settings.DREAM_SETTINGS` had no activity. This does not establish that
every TCL firmware behaves the same way. Setup detects capabilities rather than
guessing solely from the brand; onboarding explains when installer help is needed.

The companion installer can select the screensaver through the TV's already
authorised ADB connection, with the owner's explicit approval. No root,
accessibility service, manufacturer-app disabling or app secure-settings grant.
For installation plus screensaver setup in one command:

```powershell
./Install-Test.ps1 -Device '<authorised target>' -Apk './app/build/outputs/apk/debug/app-debug.apk' -ConfigureScreensaver -ScreensaverBackupPath '../my-tv.screensaver-recovery.json'
```

Build-tools 34.0.0 must be available through ANDROID_HOME or `-SdkRoot`. The
installer checks API/TV capabilities, the APK identity and signature, and an
existing Unified signer's match before installing. It stops on a mismatch;
do not clear data to install a newly signed debug build.

For an already installed Unified APK, no reinstall is needed:

```powershell
./Set-Screensaver.ps1 -Device '<authorised target>'
# After the owner approves selecting Unified:
./Set-Screensaver.ps1 -Device '<authorised target>' -Mode Enable -BackupPath '../my-tv.screensaver-recovery.json'
# Optional: include -IdleMinutes 5 only when the owner approves changing the timer.
```

Status mode is read-only. Enable saves the prior screensaver and activation
flags before writing, then reads each setting back. The existing idle timer is
preserved unless `-IdleMinutes` is supplied. Failed setup attempts restore changed
settings and report any recovery failure; never work around a firmware refusal.
Keep the recovery file private: it includes the selected TV connection address.
Repeated setup does not replace the original recovery file. Upload photos into
Unified first: the old Ambient app's private photos are separate, and Unified
ends its Dream if its own collection is empty. Verify natural idle entry, photo
display and real-remote dismissal; successful selection alone is not that test.

Restore the saved choice using the same selected TV connection:

```powershell
./Set-Screensaver.ps1 -Device '<authorised target>' -Mode Restore -BackupPath '../my-tv.screensaver-recovery.json'
```

Restore refuses to overwrite settings changed after setup. Keep native Settings
and authorised ADB available through testing; do not change default Home as part
of screensaver setup. Normal APK-only installation still cannot silently choose
a system screensaver. Without an authorised computer, use native settings when
available; a vendor restriction remains a restriction.

## Photos and network

Gallery and DreamService use the same private `files/ambient_photos` directory.
The older preview package's private collection is not readable by Unified.
Upload original files again; nothing copies or deletes the old app's data.
Known older Home and Ambient preview shortcuts are hidden by default inside
Unified's app grid; hiding does not uninstall those apps or change their photos.
An existing theme's explicit `hidden_apps` override or manually added library
shortcuts can override these defaults.
Maximum 100 JPG/PNG/WebP files, 10 MiB each, with magic-byte and decoded-dimension
validation. Photos are sampled when displayed. Gallery deletion asks first.

Wi-Fi upload is an explicit, foreground-only session bound to a private IPv4
interface on an ephemeral port. The QR contains an eight-character random
access code in its URL fragment; the browser removes that fragment. Uploads
require the code and exact Host and Origin. Eight invalid codes stop a session;
ten-minute session expiry, bounded requests and socket timeouts limit abuse.
Closing/leaving the upload screen closes both the listener and accepted socket.
No photo download, delete endpoint, cloud storage or persistent upload service.

HTTP is **not encrypted**. This is authenticated local upload for trusted home
networks, not transport security for hostile/shared networks. Never expose its
port to the internet. No telemetry, accounts, GPS or broad storage permissions.
Brunei weather/prayer overlay is opt-in in setup; photos work without it.

## Release signing and distribution

No private key, password or signing config is committed. Release packaging fails
without all four environment variables; it never falls back to debug signing.
Create a dedicated encrypted RSA key using `keytool` interactively, outside this
repository, and back it up securely. Keep its certificate for every future update.
Provide `CYTV_KEYSTORE` (absolute path), `CYTV_STORE_PASSWORD`, `CYTV_KEY_ALIAS`
and `CYTV_KEY_PASSWORD` through a local secret manager/environment. Then:

```powershell
./Build-Release.ps1 -SdkRoot '<Android SDK directory>' -Destination '<private review directory>'
```

This runs release tests, lint and R8 packaging, verifies the APK signature, and
produces SHA256SUMS.txt. Do not put passwords in command arguments, source files,
screenshots or workflow logs. Verify signer fingerprint against a separately
published expected certificate; a checksum alone does not establish authenticity.

Before approving publication: complete the physical-device checks below, resolve
the regional-data redistribution question in NOTICE.md, select and back up the
production key, set the intended versionName/versionCode, build from a clean
reviewed commit and publish source plus licence notices, APK, checksum, certificate
fingerprint and honest compatibility notes. Increasing versionCode and retaining
the same signing key are required for updates. No automatic publishing workflow
or change to the upstream CI/size gate is introduced.

## Compatibility and recovery

Android TV 8+ is a target, not a claim that every model works. Device detection
reports manufacturer/model, API, TV feature, settings/picker availability and
low-RAM status locally. API 25 and non-Android platforms are unsupported.
The prior two APKs were reported working on Xiaomi Android 9. This session
installed Unified on a TCL Android 11/API 30 set, verified it as the selected
Home, and received owner confirmation that photo upload works. Unified's own
DreamService passed natural five-minute idle entry and photo display on that set
using authorised installer setup. Xiaomi and AIFA remain unverified. See VERIFICATION.md.

Before choosing Home, record the existing default Home and screensaver in TV
settings and confirm that the remote's Settings/Input buttons still work. Keep
the original launcher enabled and an authorised recovery route available while
testing. After testing, turn off debugging normally.

Rollback: in Android Settings choose your previous Home and screensaver again.
If needed, open settings using the physical remote or an already authorised ADB
connection: `adb -s '<target>' shell am start -a android.settings.SETTINGS`.
If the vendor rejects changes, stop; do not disable, root, flash or bypass it.
The original Xiaomi packages remain installed and unchanged. Retain original
photos: clearing Unified data or removing the app deletes its private copies.

Physical test gate: D-pad focus from every edge, Back/Home/Settings and the real
remote; launch installed apps; switch HDMI and return; QR upload on Wi-Fi and
Ethernet, incorrect/expired code, pause/exit mid-upload; gallery delete/cancel;
idle Dream entry and remote dismissal; restart TV and recover previous Home.
Repeat on API 26/28 and newer firmware, low-RAM sets, Xiaomi and AIFA before
widening compatibility claims. See `VERIFICATION.md` for actual checks performed.

See [NOTICE.md](NOTICE.md) for third-party attribution and source provenance.
