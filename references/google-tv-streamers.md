# Google TV sticks and boxes

Tested on a Chromecast with Google TV 4K (`sabrina`, Google TV 14, build UTTC.250917.004). Upstream
examples cover the 4K, the HD (`boreal`) and the Google TV Streamer (`kirkwood`); read the one that
matches `ro.product.device` before you plan.

## The setup wizard owns Home and maybe the Wi-Fi

`com.google.android.tungsten.setupwraith` keeps a `RecoveryActivity` that takes Home back from any
other launcher, so it has to be disabled before the new launcher can be Home. Two traps:

1. **Wi-Fi ownership.** A network joined during first setup belongs to setupwraith:
   `dumpsys wifi | grep -o 'cname=[^ ]*'` prints `com.google.android.tungsten.setupwraith`. Android
   deletes that network the moment setupwraith is disabled, which takes the stick off Wi-Fi and ADB.
   Fix first: ask the user to Forget the network in Settings > Network & Internet and join it again,
   typing the password themselves. Then every cname reads `android.uid.system:1000`. The re-join drops
   ADB and switches Wireless debugging off; ask for the new connect port (Path B in connection.md).
   Upstream `disable.sh` skips setupwraith while it still owns Wi-Fi.
2. **Casting.** The Cast receiver (`com.google.android.apps.mediashell`) loads its device credentials from
   a provider inside setupwraith; without it phones say "Untrusted device". So ask whether anyone casts
   to this device. If yes, either debloat only (keep stock home and setupwraith) or read upstream's
   troubleshooting entry on re-enabling setupwraith after boot. If no, the Cast receiver can go too.

Order that worked: telemetry/preloaded batches, user re-joins Wi-Fi, disable setupwraith (Wi-Fi stays
up), then install the launcher (build-and-install disables `com.google.android.apps.tv.launcherx` and
Home switches on the first try).

## Remote buttons

With launcherx disabled the remote's YouTube button sends `KEYCODE_BUTTON_3` (190) to nobody. Map it in
the device theme instead of installing a key-mapper app:

```json
"app_keys": ["190:com.google.android.youtube.tv"]
```
and install with `HOME_KEY_SERVICE=1 RESTORE_KEY_SERVICES=1` so the launcher's accessibility helper
(label shown as the launcher's "Home key" service) is enabled and comes back after a force-stop. The
Netflix button (191) kept working on its own. Verify with the real remote and logcat (`START u0 ...
youtube`), and ask the user to hold Volume Up: a key-filtering service can kill auto-repeat on some
firmware; on the Chromecast 4K it did not.

## Other settings to fix on Google TV 14

- **Keyboard**: the default IME is often `com.google.android.tv.remote.service/.ImeBridgeService`
  ("type on your phone"), which never works without the phone app. Switch to Gboard:
  `ime set com.google.android.inputmethod.latin/com.android.inputmethod.latin.LatinIME`.
- **Screensaver**: disabling ambient mode (`com.google.android.apps.tv.dreamx`, `com.google.android.backdrop`)
  leaves `screensaver_components` pointing at it. Point it at the launcher's clock:
  `settings put secure screensaver_components com.gathin.tvhome/.ClockDream`.
- **Theme keys for a stick with no tuner or HDMI in**: `"live_tv_package": ""`, `"show_inputs_pill": false`.
- `com.google.android.tvrecommendations` ships disabled from the factory; leave it out of restore lists.
- Display: `wm size` shows a 3840x2160 physical size with a 1920x1080 override on the 4K. That is how it
  ships; don't "fix" it.

## Typical list on Google TV 14 (from the upstream 4K/HD examples)

Telemetry and ads: `com.google.android.feedback`, `com.android.tv.feedbackconsent`,
`com.google.android.tv.remotecontrol.logging`, `com.google.android.apps.tv.netoscope`,
`com.google.android.federatedcompute`, `com.google.android.ondevicepersonalization.services`,
`com.google.android.adservices.api`, `com.google.android.ext.adservices.api`.
Preloaded: `com.google.android.play.games`, `com.google.android.videos`, `com.android.printspooler`,
`com.google.android.marvin.talkback` (ask: screen reader). Ambient: dreamx, backdrop. Then setupwraith.
Keep: Play Store/Services, Gboard, Bluetooth, `com.google.android.tv.remote.service` (phone remote),
`com.google.android.tv.axel` (remote pairing), `com.google.android.tv.dfuservice` (remote firmware),
Assistant (`com.google.android.katniss`) unless the user drops voice.

## Verifying playback when screenshots are black

Video plays on a hardware overlay, so a screenshot during playback is black or has a noise strip. Check
instead: `dumpsys media_session` shows `state=PLAYING(3)` for the app's session, and `dumpsys audio`
lists its `AudioPlaybackConfiguration` as `state:started`. A public test video works without touching
anyone's account: `am start -a android.intent.action.VIEW -d https://www.youtube.com/watch?v=aqz-KE-bpKQ
com.google.android.youtube.tv`.

## Closing ADB on a stick

Turning USB debugging off leaves Wireless debugging listening on its own port. Have the user switch off
both (and Developer options), revoke authorisations and reboot; check 5555 and every connect port you
used with `scripts/port_check.py`. If casting is disabled, port 8009 is closed too, so use 6466 (Android
TV remote service) as the "alive" port.
