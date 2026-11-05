# Try CleanYourTV Unified with Codex or Claude Code

This is an evaluation alpha for Android TV 8/API 26 and newer. Unified installed
successfully on one TCL Android 11 TV and the owner confirmed photo upload works.
Its own screensaver remains untested; the idle test used the separate v6.3.1 app.
A friend or family member should stay
available to authorise installation and test their real remote. The original
launcher must remain enabled.

Use a trusted copy of this repository. If it is private, the owner must invite
your GitHub account first. No paid account, photo account or cloud photo service
is needed by the TV app.

Paste the following into Codex or Claude Code on a computer connected to your TV:

```text
Help me try CleanYourTV Unified from this repository on my Android TV.
Clone https://github.com/K3nnutCode/cleanyourtv-unified.git into a new local folder.
Read README.md, VERIFICATION.md and NOTICE.md first. This is an evaluation alpha.

Inspect the source and build the debug APK with JDK 17, Android SDK platform 34
and build-tools 34.0.0. Run testDebugUnitTest, lintDebug and assembleDebug. If I
provide an owner-built preview APK, check its checksum, application ID and
signature before installing it. Never execute downloaded helper scripts blindly.

Detect only already-authorised ADB devices. Ask me which device if more than one
is connected. Check that it runs Android API 26 or newer; stop on older versions.
If authorisation is needed, let me approve the TV's normal debugging prompt.
Do not scan my network, bypass verification, root, flash or lower the API minimum.

Show the intended device model, Android version and APK package before installing.
Install only com.k3nnut.cleanyourtv.unified and open
com.gathin.tvhome.HomeCandidateActivity. If a Unified installation already exists,
check its signer first; stop on any mismatch instead of deleting its data.
Preserve any older CleanYourTV or Concept B packages and their photos.

Keep the stock launcher enabled. Do not change default Home, accessibility
services, secure screensaver settings or manufacturer packages. Ask separately
before any potentially disruptive change. Let me select Home or screensaver in
native TV settings only after testing, with recovery instructions ready.

Guide me through onboarding, gallery and QR upload on a trusted home network.
Explain that the temporary upload page uses unencrypted local HTTP. Check wrong
code rejection and that uploads stop on Back or leaving the app. Ask me to test
the real D-pad, Back, Home, Settings and HDMI input switching. Test screensaver
selection, idle entry and dismissal only with my approval. Record actual results;
do not claim that untested TV models are supported.

Show me how to return to the previous Home and screensaver through TV settings.
Keep original photo files, because clearing Unified data or replacing a debug
signature deletes its private library. Turn off debugging through normal TV
settings when testing is finished. Do not publish logs, TV identifiers or photos.
```

The app's initial setup opens its gallery and supported TV settings. Installing
the APK does not choose it as the default Home or screensaver.

## Owner-built preview APK

After the repository is uploaded, the owner can open **Actions → Build preview
APK → Run workflow**. A successful run supplies a `cleanyourtv-unified-preview`
artifact containing the debug APK and SHA256SUMS.txt. GitHub artifact downloads
require access to the repository and normally require signing in. This workflow
does not publish a GitHub Release.

Keep previews labelled as debug evaluation builds. A later production signing
key cannot update a differently signed preview in place. Distribution to testers
does not resolve the regional timetable licence question in NOTICE.md.
Clean CI builds may also produce different debug signing keys. Keep the same
preview APK for a test round; do not erase an existing photo library to bypass
a signature mismatch.
