# Gotchas that cost time on real runs

## Shell

- **zsh does not word-split variables.** `T="python tv.py"; $T probe` fails in zsh with "no such file".
  Use a function: `tv() { "$UPSTREAM/tools/venv/bin/python" "$UPSTREAM/tools/tv.py" "$@"; }`.
- **Paths with spaces** (for example "My TV") break any script that stores a command line in a string. Quote
  every path and call through functions. Test generated scripts on a path with a space.
- **`echo ======` in zsh** is an equals-expansion error. Quote it.
- `cd` inside a compound command can change the agent's working directory; prefer absolute paths.
- Background jobs: one long `sleep` in the foreground may be blocked by the harness; prefer bounded
  polling loops with a timeout.

## ADB and the device

- `pm disable-user` persistence can lag (about 10 s on some boards). Wait before rebooting or pulling power.
- `adb reboot` over TCP can hang on the dropped connection; use `tv.py --reboot`. Confirm a reboot with
  `/proc/uptime`, not with "boot_completed=1" (that also reads 1 on a device that never rebooted).
- `exec-out screencap` writes broken PNGs on MediaTek; `tv.py --screenshot` captures on the device and
  pulls the file.
- Screenshots of HDMI, Live TV, DRM apps, video overlays, or a settings panel over HDMI come back empty or
  black. Check `dumpsys activity activities`, `dumpsys media_session`, `dumpsys audio` instead.
- Identical screenshots byte for byte: screencap is returning a stale frame; check `mCurrentFocus` in
  `dumpsys window`, force-stop the app and capture again.
- `logcat` ring buffers on TVs are small (256 KiB). Clear (`logcat -c`) right before a test you want to
  read back, and read it soon after.
- `getevent -lt` through `tv.py` blocks until its read timeout and may show nothing for remotes that go
  through a vendor HAL. Use logcat activity starts to corroborate button presses instead.
- `dumpsys media_session` prints states as `PLAYING(3)`, not `state=3`; grep for the word.
- `wm size` / `wm density` show physical values next to overrides. An override from an old experiment
  (or a stick that ships 1080p UI on a 4K panel) is not a launcher bug; read
  `settings get secure display_density_forced` (empty is normal) before touching anything.

## Process

- Ask questions in rounds of at most four, each with a recommended option. Put long app lists in groups
  of four and say what happens to anything not ticked.
- When the user only answers part of a request (one port instead of two, "done" without the values),
  ask again for exactly what is missing, and say why you need it.
- Keep a TASK_STATE.md per device and update it after each phase; it is how you resume after the
  conversation is summarised.
- Before reporting done, re-read the acceptance criteria and attack your own result: open the file most
  likely to contradict you, and say what you did not verify.
