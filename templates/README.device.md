# <Device name> - what was changed and how to change it back

Write this in the user's language. Lead with the outcome, keep commands copy-pasteable (one per block),
and leave out Wi-Fi names, account names, emails and serial numbers.

## Outcome
<Date. Model, Android version, build. How many packages were disabled (all reversible), what the new
home looks like (dock apps, wallpaper), DNS, what was verified on the device and what the user checked
with the real remote.>

## Files
| File | What it is |
|---|---|
| `install.sh` | Build and install the launcher, push this device's theme, apply settings |
| `restore.sh` | Re-enable everything; `--launcher` stock home, `--dns` DNS off, `--all` both |
| `theme/config.json` | This device's dock, keys, inputs and wallpaper settings |
| `lists/debloat.txt` | What was disabled, with a reason per line |
| `backup/` | Snapshot taken before any change |

## Getting ADB back for any of the commands below
<Path A or B from the skill's references/connection.md, written for this device. Remind the reader to
switch debugging off afterwards (both switches on Google TV).>

## Re-enable one app
<`tv.py 'pm enable <package>'` and a short table of the packages people most often want back.>

## Restore everything
<`./restore.sh --all`.>

## Change the dock or its order
<Edit `theme/config.json` `dock_apps` (or config.xml if this device has no theme), push with
`tools/theme.sh theme`. On the TV: hold OK on the Settings pill > Launcher settings.>

## Change the wallpaper
<Put a dark 1920x1080 JPEG under 300 KB as `theme/wallpaper.jpg` or several in `theme/wallpapers/`, set
`"wallpaper": true`, push the theme. `"wallpaper": false` for none.>

## Ad-blocking DNS
<Current state, that it does not block YouTube ads, and the undo command.>

## Good to know
<Firmware re-enablers, what boots first after power-on, features traded away (casting, notification
panel), anything not tested.>
