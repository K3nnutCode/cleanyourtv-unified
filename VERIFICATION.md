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

## Device testing limits

Windows Computer Use inspected the available desktop apps; no TV mirror or
Android emulator was open. `adb devices -l` found no connected devices.
No APK was installed on a TV. No deployed package, default Home, screensaver,
manufacturer launcher or TV system setting was changed.

The owner's prior Xiaomi Android 9 success applies to the original two APKs.
Unified has no physical Xiaomi, AIFA or other model verification yet. Remote,
HDMI, idle Dream entry, real browser QR flow and reboot/recovery tests remain
required before calling it stable or publicly supported. The uploader's
plaintext transport is intentional trusted-LAN scope, not HTTPS security.

## Distribution gate

Retain a production signing key and test the actual release APK on hardware.
Resolve the PDI timetable redistribution licence noted in NOTICE.md before
public distribution. No remote branch push, PR merge, tag, release or other
production repository change is performed by this local implementation.
