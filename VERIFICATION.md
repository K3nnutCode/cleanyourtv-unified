# Verification — 5 November 2026

This is an alpha integration, not a certified public release.

This report records the initial local verification. The standalone repository
was prepared from that verified integration and is published at
https://github.com/K3nnutCode/cleanyourtv-unified. Statements below about no
remote changes describe the initial local-build session; publication of this
separate repository does not modify the original CleanYourTV repository or TVs.

## Source and APK identification

Home branch: `feature/home-v831-ambient-v631`, commit
`1ea7ee707013a253a587eda7b76f6d1cc9322772`.
Ambient branch: `feature/ambient-v631-qr-layout`, commit
`8316bbb2475e2580a584df27b6bb0fa69b21318e`.
New local work: `feature/cleanyourtv-unified`, based on the Home revision.

The downloaded original archives were inspected with Android build-tools:

| Original APK | Compiled package | Compiled version |
| --- | --- | --- |
| Home v8.3.1 archive | com.k3nnut.tvhome.home.candidate.v831 | code 7, name 2.6 |
| Concept B v6.3.1 archive | com.k3nnut.tvhome.ambient.preview.v631 | code 64, name 6.3.1-rc1 |

Original APK SHA-256 values:

```text
68bade6c62378c105cf97de214ba9d1895bb0e49e33062ab5d4b06c62018e9c4  original Home app-debug.apk
5b342b497fc7b85695b9c4bb341d2e1aeb26f3bc23df48479786904f6f24d3a1  original Ambient app-debug.apk
```

These are source-branch and APK-metadata matches. Byte-for-byte reproduction
of the old APK builds was not established. The old APK labels are not the
Home APK's actual versionName; the distinction above is intentional.

## Checks

JDK 17.0.20.1, Gradle 8.9 (wrapper checksum verified), Android platform 34,
build-tools 34.0.0, Android Gradle Plugin 8.5.2 on Windows.

- Debug compilation and APK packaging: passed.
- JVM suite: 192 tests, zero failures/errors; both debug and release variants.
  Includes inherited navigation/photo/QR/protocol tests and new deadline,
  cancellation and capability-report tests.
- Debug and release lint: zero errors, 89 warnings each. Warnings remain and
  are not claimed resolved; reports include inherited source/resources and
  incomplete translations.
- R8/minified release packaging: passed with an ephemeral RSA evaluation key.
- Full `Build-Release.ps1` workflow: signed APK, apksigner verification and
  checksum-file generation exercised with a temporary key. No production key
  was created or committed. Evaluation signing is not a retained update identity.
- Missing-credential `assembleRelease`: deliberately failed in `packageRelease`
  with “Release signing is required”; no debug fallback.
- Compiled APK audit (`verify_apk.py`): correct new package, API 26/34,
  exactly one registered Home activity, internal gallery, enabled DreamService
  protected by BIND_DREAM_SERVICE, disabled accessibility helpers, no backup,
  and only INTERNET/ACCESS_NETWORK_STATE/ACCESS_WIFI_STATE runtime permissions.
- Evaluation APK signature verified by Android apksigner (APK v2 scheme).
- Original `launcher/` tree unchanged from the Home base revision.

The broad upstream Python suite was attempted. Shell integration cases hit
Windows shell execution errors; the run was interrupted. It is not reported as
passing. The Android/JVM checks above completed separately and successfully.

## Initial session device testing limits

Windows Computer Use inspected the available desktop apps; no TV mirror or
Android emulator was open. `adb devices -l` found no connected devices.
No APK was installed on a TV. No deployed package, default Home, screensaver,
manufacturer launcher or TV system setting was changed.

The owner's prior Xiaomi Android 9 success applies to the original two APKs.
Unified has no physical Xiaomi, AIFA or other model verification yet. Remote,
HDMI, idle Dream entry, real browser QR flow and reboot/recovery tests remain
required before calling it stable or publicly supported. The uploader's
plaintext transport is intentional trusted-LAN scope, not HTTPS security.

## Follow-up TCL evaluation — 5 November 2026

Source under test: published commit `b93060ef7ea77d16c8750dae7ea62fad8376e911`.
The connected GitHub plugin verified preview workflow run `41961958249` and
artifact `13385942118` against that commit. ZIP SHA-256 matched GitHub's digest:
`a5a89fafae36fe453efeff331211c2030a02a87651aa09e98fa837bf1e1c620f`.
APK SHA-256 matched bundled SHA256SUMS.txt:
`4d236c0570c7155534866906b595d2a508661a6511debe96c56d570e11f15a17`.
Android apksigner independently verified the APK v2 signature; certificate
SHA-256: `9e08573cd99725df306f2a50d7484daec55d0578c7bd905dbafe0f33f7ce49e8`.
This establishes artifact integrity/signing identity, not reproducible builds
or a permanent production signing identity.

| Check | Actual result |
| --- | --- |
| Device | One TCL Smart TV, Android 11/API 30, TV/Leanback features |
| Installation | Unified was absent; verified CI preview installed successfully |
| Onboarding/Home | Onboarding and gallery observed; Unified later verified as selected default Home |
| Upload | Owner reports photo upload works; exact browser/connection path not independently recorded |
| Existing photo screensaver | Ambient v6.3.1 automatically entered after five minutes idle and visibly displayed photos |
| Unified DreamService | Initially untested; later approved assisted selection/idle-entry/photo-display test passed, recorded below |
| Preview shortcuts | Five enabled old preview apps hidden using Unified's saved shortcut list; cleaned grid visually verified |
| Previous Home removal | At owner's later explicit request, removed Home v8.3.1 with app data retained after saving/verifying its original APK |
| Independent local build | 192 JVM tests, zero failures/errors; debug lint zero errors and 89 warnings; assembleDebug passed |

The owner's five-minute request changed only `screen_off_timeout` from 600000
to 300000 ms. A fresh idle interval remained uninterrupted: the TV was Awake
at approximately 65, 126, 195 and 247 seconds; at 306.7 seconds it was Dreaming.
DreamManager identified the separate Ambient v6.3.1 service as connected and
started, with `mCurrentDreamIsTest=false`. The five-minute timer remains set.
This is natural idle-entry evidence for v6.3.1 with Unified as Home, not evidence
that Unified's own screensaver or photo library is fully integrated on hardware.

The stock Google TV launcher was already disabled when this session connected;
the agent did not disable it or change its state. Native Settings and authorised
ADB were available as recovery routes. Installing a new Home candidate initially
caused Android's Home chooser to appear. Do not assume installation preserves
the previous default association. No accessibility, root or firmware change.

The local debug build has a different signer from the installed CI preview and
was not installed over it. No data was cleared to bypass a signature mismatch.
Source changes after this test are local review work, not deployed APK changes.

Remaining checks: wrong/expired upload codes; upload shutdown on Back/Home and
mid-transfer; gallery delete/cancel; exact Wi-Fi/Ethernet coverage; owner-reported
remote navigation and HDMI results; reboot and
recovery. Unified selection/idle entry/photo display were later verified below. No Xiaomi/AIFA coverage or
universal compatibility claim is established.

## Requested setup improvements

- Hide known older Home/Ambient preview shortcuts by default in Unified. The
  configuration now lists those exact packages in `hidden_apps`;
  they remain installed and usable outside Unified. Existing theme overrides
  and explicitly added library shortcuts must be considered during upgrades.
- Reduce manual screensaver setup. A local feature branch now implements the
  authorised installer-assisted flow described below. Ordinary apps still cannot
  silently write Android's secure settings; native selection is the APK-only
  path when available. No universal model-support claim is established.
  References: [Settings.Secure](https://developer.android.com/reference/android/provider/Settings.Secure)
  and [DreamService](https://developer.android.com/reference/android/service/dreams/DreamService).

## Assisted screensaver setup implementation

Diagnosis on this TCL: `query-services` lists Unified's enabled DreamService,
but `android.settings.DREAM_SETTINGS` resolves to no activity. The missing
native picker is independently observed; a general vendor allowlist or defect
in Dream registration was not established.

`Set-Screensaver.ps1` detects API/TV capabilities and picker availability. Its
default Status mode is read-only. Explicit Enable selects the registered Unified
component and activation flags through already authorised ADB, after saving an
exclusive local recovery snapshot. It preserves the idle timeout unless requested.
Every write is read back; setup failures attempt rollback and report failures.
Restore verifies the selected connection and refuses to overwrite a newer owner
choice. Recovery files are private and excluded from Git by their documented
`.screensaver-recovery.json` suffix. No app permission grant, manufacturer-package
mutation, root or hidden API is used. The PowerShell companion is for Windows
installation, not a silent APK-only setup guarantee.

Install-Test.ps1 supports an explicit screensaver configuration option and now
checks APK identity, signature, TV minimum API and existing signer before install.
On the actual TCL, its signer-mismatch path correctly rejected the newly built
local APK before installation. Status mode correctly reported the missing picker
and the existing v6.3.1 selection. Onboarding now explains installer help when the
native picker is absent and displays Unified selection status when readable.
Standard Dream preview metadata is included for pickers that support it; this
does not create a missing vendor picker.

Local validation: Android testDebugUnitTest, lintDebug and assembleDebug passed;
192 tests, no failures/errors; zero lint errors and 89 warnings. The simulated
ADB integration tests cover selection, timer, idempotency, recovery snapshot
protection, exact/absent-setting restore, refused-write rollback, newer-choice
protection, connection binding, old API, missing service and unsafe recovery data.
The preview workflow now includes these script tests; at initial implementation
that new CI step had not yet executed on GitHub. No new-signer APK was installed on the TCL.

The owner separately approved the live selection test. Enable was run against
the existing, verified CI preview on the TCL without reinstalling it. It saved
the prior Ambient v6.3.1 choice and left the existing 300000 ms timer unchanged.
The TCL retained Unified's component without using its missing native picker.
A fresh uninterrupted idle interval was Awake at 30, 76, 171 and 251 seconds.
At 314.1 seconds, power reported Dreaming and DreamManager identified
`com.k3nnut.cleanyourtv.unified/com.gathin.tvhome.AmbientPhotoDream` with a
connected service, start broadcast sent and `mCurrentDreamIsTest=false`.
A local screenshot visually confirmed a photo and the enabled regional overlay.
This independently verifies Unified's own idle playback on this one TCL; it is
separate from the earlier v6.3.1 test. Unified remains selected at five minutes;
the original recovery snapshot remains private and local. The owner confirmed
that pressing Back on the actual remote returned to Unified Home normally.
Repeated Enable on the actual TCL performed no writes and preserved the original
recovery snapshot (hash compared before/after). New onboarding
UI/metadata are build-verified only, because the new-signer APK was not installed.

## User-readiness audit

A subsequent clean Windows build ran both debug and release JVM suites, both
lint variants and debug assembly. Before the upload-response regression tests,
each suite passed 192 tests, each lint variant had zero errors and 89 warnings.
Release packaging without signing credentials was separately confirmed to fail
with the required signing guard. The PowerShell 7 setup/recovery integration
suite passed again. Windows PowerShell 5 was blocked by this computer's script
execution policy; that policy was not changed. QUICK_START.md now explicitly
requires PowerShell 7 and describes the other SDK/JDK/ADB prerequisites.

The installed CI APK's local upload page responded successfully, and a wrong
access code returned HTTP 403. That live check exposed truncated rejection-body
delivery when a client was still sending a photo. Source now consumes only a
bounded rejected body through the existing deadline/cancellation stream and
writes the response together. The invalid-code session limit also applies after
interrupted requests. Three new JVM regressions cover a full rejection over a
real loopback TCP connection, exact body boundaries and incomplete/unbounded
length rejection. Final debug and release suites each pass 195 tests. This source
fix is not installed on the TV because its debug signer differs; do not describe
the old APK's rejection message as fixed on hardware.

On the actual TCL, Back during an authenticated incomplete transfer closed the
active connection and the listener; a new connection was refused. The original
two photo files were unchanged and no partial file remained. Unified Home,
Unified's selected Dream and the five-minute timeout were verified afterward.

The old preview workflow only offered a pre-update APK and omitted the new setup
scripts. It now validates pull requests and main updates, runs both test/lint
variants plus script tests, and produces bundles on main/manual runs. Bundles
include setup/recovery scripts, QUICK_START, README, tester/verification notices,
source revision and build-run link; checksums cover the installation files.
The copyable agent prompt now permits the approved, snapshot-backed screensaver
setup path rather than incorrectly requiring native selection on every TV.

Readiness remains guided alpha evaluation, not unrestricted public release.
Permanent signing and timetable redistribution clearance are unresolved. Additional
models, firmware/API coverage, reboot/recovery, real HDMI switching and the full
remote matrix remain incomplete; session-expiry behaviour was not timed on hardware.

## Distribution gate

Retain a production signing key and test the actual release APK on hardware.
Resolve the PDI timetable redistribution licence noted in NOTICE.md before
public distribution. No remote branch push, PR merge, tag, release or other
production repository change is performed by this local implementation.
