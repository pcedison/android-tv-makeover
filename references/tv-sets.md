# TVs with a tuner and HDMI inputs

Tested on a Philips 70PUH8217/96 (TP Vision, board `PH1M_EA_9970A`, MediaTek MT5895, Android TV 11,
build RTT2.211108.001 2769). Upstream has several examples on that board; the general lessons below
apply to other vendors (Sony, TCL, Hisense, Xiaomi) too.

## Vendor packages: names lie, bindings tell

Vendor layers (`org.droidtv.*` on Philips, `com.mediatek.*`, `com.tcl.*`, `com.xiaomi.*` ...) mix
telemetry with the TV engine. Before deciding:

- `dumpsys package <pkg>`: components, intent actions, `sharedUser`, `PERSISTENT` flag, code path.
- `scripts/bindings.py <substring> ...`: which other processes bind its services. On the Philips set the
  "DAC" analytics uploader (`org.droidtv.candeebug`) was bound by the TV app, channels, settings, power
  manager and more. Upstream had disabled it safely on the same board, so it went in its own batch with
  a full TV/HDMI/settings check; on a board with no such evidence, ask or keep.
- Same-board examples' DO NOT DISABLE blocks are evidence from someone who walked every binding. On
  Philips: `eum` (contextual help) and `aurora` leave the persistent `xtv` engine retrying forever, and
  without `eum` the SOURCES drawer opens and vanishes; Ambilight/Hue/AmbiAir/Sunrise, the browser engine
  and HbbTV pieces stay. Tell the user when this overrides something they wanted gone.
- Region bloat (European satellite operators on an Asian set, UK Freeview apps) is often already
  factory-disabled; check `pm list packages -d` in the backup.

## Upstream's TV-input guard

`tools/disable.sh` skips packages that request `TV_INPUT_HARDWARE`. Usage loggers and demo apps request
it too. If `pm query-services --components -a android.media.tv.TvInputService` does not list the package,
it is a false positive: disable it alone with `TVINPUT_ALLOW=1` and re-run the TV/HDMI checks.

## Verification on a TV

`scripts/verify.sh` with `VERIFY_TV=1` also checks:
- the Sources/Input drawer (`KEYCODE_TV_INPUT`) stays open,
- the vendor Live TV activity (`VERIFY_LIVETV=org.droidtv.playtv/.PlayTvActivity` on Philips),
- an HDMI input via the TV input framework: `VERIFY_HDMI=<input id>` from
  `dumpsys tv_input | grep -oE 'TvInputInfo\{id=[^,]*'` (Philips: `com.mediatek.tvinput/.hdmi.HDMIInputService/HW5`).

Live TV, HDMI and DRM apps give 0-byte screenshots, and so does a settings panel drawn over HDMI. That is
the TV, not damage: check the resumed activity with `dumpsys activity activities` instead.

## Launcher settings specific to TVs

- `live_tv_package`: the vendor TV app (`org.droidtv.playtv` on Philips; upstream's default is a MediaTek
  one that does not exist there). Add it to `hidden_apps` too: the Inputs menu already covers it.
- The Inputs menu lists every input the board reports, including Component/Composite/SCART/VGA the set
  physically lacks. Compare with the vendor's own sources drawer and hide the extras in `config.xml`
  (`input_sources` is config.xml-only): `<item>HW1=-</item>` ... by the input id's last part.
- After power-on many vendor firmwares open Live TV or the last source themselves (Philips
  `PlayTvActivity` right after `FallbackHome`). It is not the launcher; Home goes to the launcher. Tell the
  user, and point them at the TV's own "switch on with" setting instead of fighting it.
- The vendor's global key handler (Philips `org.droidtv.GlobalKey`) usually keeps Netflix/YouTube/
  SOURCES/Guide/Settings buttons working after the stock launcher is gone; Google TV sets route them
  through the stock launcher and need `app_keys`. Test with the real remote either way.

## Firmware that re-enables packages

After the reboot check, a package with `enabled=1` (not `0`/default) came back on purpose. On the Philips
set this was the Mimi hearing-test app; upstream notes Chromecast built-in and Play-Fi doing the same on
that board. Comment it out in the list with the reason and hide its launcher tile if the user wanted it
gone.

## Memory and performance expectations

Debloating a TV mostly buys privacy and a cleaner home, not RAM: on the Philips set `MemAvailable` rose by
roughly 60 MB. Measure the launcher with `dumpsys gfxinfo com.gathin.tvhome` (reset, press keys, read
"Janky frames"); MT5895 drew 0 janky frames out of 464, so `reduced_motion` was not needed.
