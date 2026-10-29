---
name: android-tv-makeover
description: Debloat an Android TV or Google TV device over ADB (TVs such as Philips, Sony, TCL, Xiaomi, Hisense, and streamers such as Chromecast with Google TV, Google TV Streamer, Nvidia Shield), replace its home screen with a clean Apple TV style launcher built from source, verify every step on the real device, and close network ADB afterwards. Built on the open-source cleanyourtv project. Use this skill whenever someone wants to remove bloatware, ads, recommendation rows or telemetry from a smart TV or TV stick, replace or customise a TV launcher or home screen, remap a dead remote button after a launcher change, set ad-blocking DNS on a TV, or undo/restore such changes, even if they only say "clean up my TV", "my TV is slow and full of ads", "make my Chromecast home screen simpler" or "set up the office TV like my home one".
---

# Android TV makeover

You will work on a real TV or streamer the user owns, over ADB, in small verified steps. The work is
reversible by design: packages are disabled, never uninstalled, and every change gets a restore path
before it is made. The upstream project **cleanyourtv** (MIT, https://github.com/Gathin23/cleanyourtv)
supplies the ADB client, the safety-checked disable/restore tools, per-device example lists and the
launcher source. This skill adds the workflow, the decisions to ask the user about, and the lessons
from real runs that upstream's prompt does not spell out.

Read this file first, then the reference that matches the device:
- `references/connection.md` - every way of getting ADB up (classic 5555, Wireless debugging pairing, macOS quirks).
- `references/google-tv-streamers.md` - Chromecast with Google TV, Google TV Streamer and other Google TV 12+ sticks.
- `references/tv-sets.md` - TVs with a tuner and HDMI inputs (vendor TV app, inputs menu, vendor packages).
- `references/launcher.md` - building, configuring and verifying the launcher; per-device themes.
- `references/gotchas.md` - shell and device traps that cost time (read before your first command).

Bundled scripts live in `scripts/` (run them with bash/python3, they need `TV_HOST` and `UPSTREAM`
set) and fill-in templates in `templates/`.

## Ground rules, and why they exist

- **Disable, never uninstall** (`pm disable-user --user 0 <pkg>`). A disabled package comes back with one
  `pm enable`; an uninstalled system package may need a factory reset.
- **Back up and write the restore script before the first change.** If a batch breaks the TV, the user
  needs a one-line way back while you still have ADB.
- **Ask before anything that depends on the user's preferences**: streaming apps, voice assistant,
  casting, firmware updaters, vendor features, dock apps, DNS. Bloat to one household is the
  family's favourite app to another. Batch questions (at most four per round) and give a recommendation.
- **Disable in small batches and verify each one on the device** (screenshot plus `dumpsys`), because a
  batch can take something load-bearing with it and you cannot tell which line did it afterwards.
- **One `pm` command per shell call.** Chained `pm` commands can silently stop after the first.
- **Never start factory/test packages** (names with factory, fac, production, AT, `mediatek.factorymenu`)
  even to look: on some boards that flips a factory flag the shell cannot undo. Use `dumpsys package`.
- **Never disable Android core packages** (permission controller, package installer, ext services/shared,
  module metadata, `overlay.modules*`, `com.android.providers.*` apart from calendar/contacts/user
  dictionary/blocked numbers, systemui, shell, phone, settings, tv.settings, `android`), nor what the
  TV needs to work (TV app and input services, input/source menu, remote and Bluetooth pairing,
  keyboard, Play Store and Play Services). Upstream `tools/disable.sh` refuses core packages; keep using it.
- **An injected key proves nothing about a remote button.** Ask the user to press the real button and
  corroborate with `logcat` activity starts.
- **Close network ADB at the end** and prove it: port 5555 plaintext ADB is a remote shell for anyone on
  the LAN if left open.
- **Respect networks you don't own.** On an office or shared network, do not scan or sweep; ask the
  user for the device IP and the Wireless debugging ports shown on screen. Never type Wi-Fi passwords or
  account credentials yourself; the user enters them on the device.
- **Trust `getprop`, not the label.** Users misremember models (a "Chromecast HD" turned out to be the
  4K `sabrina`); pick reference lists by `ro.product.device` / board and build.

## Phase 0 - Workspace

Use one project folder for the upstream clone and one sub-folder per device, so two devices never share
a backup, list or theme:

```
<project>/
  cleanyourtv/                 # upstream clone (shared)
  <device-slug>/               # e.g. home-philips, office-chromecast
    TASK_STATE.md  backup/  lists/  shots/  theme/  README.md  restore.sh  install.sh
```

1. Clone upstream once (ask before downloading anything; give sizes): `git clone --depth 1
   https://github.com/Gathin23/cleanyourtv.git cleanyourtv`. Record the commit in TASK_STATE.md.
   Then `python3 -m venv cleanyourtv/tools/venv && cleanyourtv/tools/venv/bin/pip install -r
   cleanyourtv/tools/requirements.txt`.
2. Skim upstream `AGENTS.md` and `PROMPT.md`; they are the safety contract this skill builds on. Delegate
   wide reading (for example "find every example for this board") to a subagent if you have one.
3. Copy `templates/TASK_STATE.md` into the device folder and fill in the acceptance criteria. Update it
   after each phase: long sessions get summarised, and this file is how you resume without guessing.
4. Export `UPSTREAM=<project>/cleanyourtv` and `TV_HOST=<ip>` for the bundled scripts.

## Phase 1 - Identify and connect

Ask, in one round: brand/model (or what the settings "About" page says), what the device is used for
(family room, meeting room, break room), how it reaches the network (Wi-Fi, built-in Ethernet, USB
Ethernet adapter), what is plugged into its USB ports, and whether the user may change this device
(company equipment needs the owner's or IT's OK). Then follow `references/connection.md`.

Stop early, and say so plainly, for platforms this cannot work on: Samsung Tizen, LG webOS, Roku, Apple
TV, older cast-only Chromecasts (no remote, no Android settings). Fire TV is mostly out too (see
upstream). Offer what still helps there: the set's own privacy toggles and DNS filtering on the router.

Once connected, run `cleanyourtv/tools/tv.py --probe` and `getprop ro.product.device` /
`ro.build.fingerprint`, then find matching upstream examples: `grep -ril <device-or-board>
cleanyourtv/examples/*/debloat.txt`. A list from the same board and build, with its DO NOT DISABLE block
and quirk notes, is the best evidence you will get. Read it in full.

## Phase 2 - Back up

Run `scripts/backup.sh <device-dir>`. It saves package lists (all/-d/-e/-s/-3), getprop, settings
global/secure/system, display size/density (with overrides), HOME resolution and candidates, the Wi-Fi
network's creator (`cname`), the default IME and screensaver. Take a baseline screenshot of the stock
home and the all-apps screen; they also identify apps whose package names say nothing.

## Phase 3 - Decide what goes

1. Classify every enabled package: telemetry/analytics, vendor ads and recommendation services,
   background services the user does not need, preloaded apps, streaming apps, and must-keep.
2. For vendor packages, read `dumpsys package <pkg>` components and actions, and check who binds them:
   `scripts/bindings.py <pkg-substring> ...` lists other processes holding a binding. A telemetry package
   bound by the TV app, settings and power manager is load-bearing: give it its own batch and test
   harder, or keep it if a same-board example says so.
3. Follow the matching example's DO NOT DISABLE block even when the user ticked something for removal;
   tell them why (for example, Philips Ambilight/Hue packages are bound by the TV engine and the sources
   drawer breaks without `eum`).
4. Ask the preference questions with recommendations: which streaming apps they use (in groups of four,
   say what will be disabled by default), voice assistant, casting, firmware updates, vendor features,
   then later the dock (4-7 slots, which apps, order) and ad-blocking Private DNS (ask whether the router
   or company network already filters DNS: Private DNS bypasses it; it never blocks YouTube ads).
5. Write `<device>/lists/debloat.txt` from `templates/debloat.txt`: a header with model, build, what was
   kept and why, then `## batch N - <theme>` sections with a comment on every line. Cut the batches with
   `scripts/cut_batches.sh <device>/lists/debloat.txt`.
6. Write `<device>/restore.sh` from `templates/restore.sh` now, before the first disable.

## Phase 4 - Debloat in verified batches

For each batch:
1. State what you expect to see if it works, then run `cleanyourtv/tools/disable.sh <device>/lists/batchN.txt`
   (it records an undo file in `~/.cleanyourtv/` and refuses core packages).
2. If the TV-input guard skips a package ("requests TV_INPUT_HARDWARE"), check
   `pm query-services --components -a android.media.tv.TvInputService`: if the package is not listed, it is
   a false positive. Disable it alone with `TVINPUT_ALLOW=1` and verify again.
3. Run `scripts/verify.sh <device> bN` and look at the screenshots. It presses Home, opens Settings and a
   streaming app, and (with `VERIFY_TV=1`) the sources drawer, Live TV and an HDMI input; it prints the
   resumed activity for each and any new crash. Fix before moving on.
4. After the last batch run `scripts/idle_loop_check.sh <device>`: a disabled package can leave a
   persistent process retrying forever with the same PID; the check counts repeating log lines over 30 s
   idle and greps for your disabled packages.

If `pm disable-user` is refused for everything, stop: that firmware cannot be debloated from the shell.

## Phase 5 - Launcher

Read `references/launcher.md` first. In short: check the device accepts sideloads and its SDK meets
upstream `minSdk`; install JDK 17 and Android SDK platform/build-tools 34 only after the user agrees to
the downloads and explicitly agrees to accept the Android SDK licence; keep upstream `config.xml`
generic and put per-device settings (dock, Live TV app, inputs pill, app keys, wallpaper) in
`<device>/theme/config.json`, pushed with `tools/theme.sh`. Install with upstream
`launcher/build-and-install.sh` (wrapped by `templates/install.sh`), which disables the stock launcher
only after the new one runs, then confirms Home with `dumpsys activity activities | grep mFocusedApp`.

Google TV devices need the setup wizard handled first and usually a remote-key mapping; TVs need the
Live TV package and the inputs list set. See the device references.

Then check D-pad behaviour with screenshots (Right along the dock, Down one row at a time, Up from the
dock to the top bar, top-bar ends hold), open the inputs menu and pick an input, measure jank with
`dumpsys gfxinfo com.gathin.tvhome` after a burst of key presses, and have the user press every
physical button (Home, Back, app buttons, Input/Sources, Settings, mic, holding Volume Up).

## Phase 6 - Reboot check

Wait at least 10 s after the last `pm` (some boards persist package state late), save `pm list packages
-d`, reboot with `tv.py --reboot` (plain `adb reboot` over TCP can hang), confirm with `/proc/uptime`
that it really rebooted, and diff the disabled list. Firmware that re-enables a package at boot is
noted in the list header instead of being disabled again every boot; hide its tile in the launcher if
the user wanted it gone. Re-check Home, key services (`dumpsys accessibility`), Wi-Fi, DNS and crashes.
Google TV sticks close port 5555 and switch Wireless debugging off at reboot: ask the user to switch it
on again (no new pairing) and send the new port.

## Phase 7 - Deliverables

In the device folder: `README.md` from `templates/README.device.md` in the user's language (re-enable an
app, full restore, change dock order, change wallpaper, undo DNS, how to get ADB back), `restore.sh`
(test it on one harmless package, then disable that package again), `install.sh` (run it once end to
end). If you can spawn a fresh-context verifier, give it the paths and acceptance criteria, not your
reasoning. Keep Wi-Fi names, emails, serials, account names and IPs out of anything meant to be shared.

## Phase 8 - Close ADB and prove it

Ask the user to revoke USB debugging authorisations, switch off Wireless debugging and USB debugging
(and Network debugging where it exists), switch off Developer options, and reboot. If the network came
over a USB Ethernet adapter, have them replug it and confirm the device is on Ethernet again. Then run
`scripts/port_check.py <ip> --closed 5555,<every wireless debugging port you used> --alive <a port that
is open on this device, e.g. 6466 or 8009>`. Only "refused" on the ADB ports while an alive port answers
proves ADB is closed; a timeout or "host down" means the device is off or elsewhere, not closed.

## Reporting to the user

Lead with the outcome, then what changed, what you kept on purpose (and why), what the firmware
re-enabled, what was verified by observation versus reported by the user, and what was not tested.
Report failures with their output. Offer optional extras only after the core job is done (a theme or
wallpaper, a before/after comparison with private details blurred).
