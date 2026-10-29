# The launcher

Upstream's `launcher/` is a small native Android TV home screen (package `com.gathin.tvhome`, Java,
RecyclerView, no network permission): black background or wallpaper, a dock row in a rounded band, a
grid below it, a glass focus highlight, the focused app's name with a glow sampled from its banner,
greeting, clock and date top left, Inputs / Wi-Fi / Settings pills top right.

## Before building

- The device must accept sideloads and meet `minSdk` (26 = Android 8.0): compare
  `getprop ro.build.version.sdk` with `grep minSdk launcher/app/build.gradle`.
- Toolchain (ask before downloading; say roughly 0.9 GB in total):
  - JDK 17. Gradle 8.9 / AGP 8.5 refuse newer JDKs ("Unsupported class file major version"); a Mac with
    only JDK 21+ needs `brew install openjdk@17` (a formula: no sudo, unlike the temurin cask).
  - Android SDK: `brew install --cask android-commandlinetools`, then
    `sdkmanager --sdk_root=<sdk> "platforms;android-34" "build-tools;34.0.0"`. Accepting the SDK licence
    (`yes | sdkmanager --licenses`) is accepting an agreement: get the user's explicit OK first.
  - Gradle and its dependencies download on the first build (official services.gradle.org, pinned
    SHA-256; Google and Maven Central).
- Build and install with `launcher/build-and-install.sh` (env: `TV_HOST`, `JAVA_HOME`, `ANDROID_HOME`;
  optional `HOME_KEY_SERVICE=1`, `INPUT_KEY_SERVICE=1`, `RESTORE_KEY_SERVICES=1`, `STOCK_LAUNCHER`).
  It checks the SDK, builds, pushes with md5 check, installs, starts the launcher, disables the stock
  launcher only after that, sets Home and verifies it; on failure it rolls back. Wrap it per device with
  `templates/install.sh`.

## One build, one theme per device

`launcher/app/src/main/res/values/config.xml` is compiled into the APK, so every device built from the
same checkout gets the same defaults. Put what differs per device in `<device>/theme/config.json` and
push it with `tools/theme.sh <device>/theme` (no rebuild, about 30 s). Theme keys that matter most:

| Key | Use |
|---|---|
| `dock_apps` | Package names in dock order; missing apps are skipped |
| `columns` | Dock slots and grid columns, 4-7 |
| `live_tv_package` | Vendor TV app; `""` on sticks |
| `show_inputs_pill` | `false` on sticks without HDMI in |
| `app_keys` | `"190:com.google.android.youtube.tv"`, `"scan:490:<pkg>"`, `"hold:..."`, `"input:<id>"` |
| `restore_key_services` | `true` with `RESTORE_KEY_SERVICES=1` at install |
| `wallpaper`, `wallpaper_rotation_minutes`, `wallpaper_dim` | Picture(s) in `theme/wallpaper.jpg` or `theme/wallpapers/` |
| `home_idle_clock_minutes` | Launcher clock screensaver on Home (useful on OLED sets that reset the system screensaver) |
| `reduced_motion` | For GPUs that drop frames; measure first |

Keys only `config.xml` carries (`input_sources`, `settings_key_scancodes`) need a rebuild; changing them
changes every device built from that tree, so note it in each device README.

A theme push replaces the device's `config.json`. To use one of upstream's wallpaper themes on a device
that has its own keys, copy the theme's `wallpaper.jpg`/`wallpapers/` into `<device>/theme/` and add the
`wallpaper` keys, instead of pushing upstream's theme folder (some, like `glass` and `sweden`, also
override `dock_apps` and `columns`).

## Verify the takeover

- `cmd package resolve-activity --brief -a android.intent.action.MAIN -c android.intent.category.HOME`
  and, after pressing Home, `dumpsys activity activities | grep mFocusedApp` must both name
  `com.gathin.tvhome/.MainActivity`. `set-home-activity` can print Success and change nothing.
- With key helpers: `settings get secure enabled_accessibility_services` lists the service and
  `dumpsys accessibility` shows it bound.
- D-pad: Right along the dock, Down exactly one row per press, Up from the dock to the top bar, top-bar
  ends don't fall through, last focused tile remembered. Screenshot each.
- Inputs menu lists only real inputs; picking HDMI 1 resumes the vendor TV app.
- Jank: `dumpsys gfxinfo com.gathin.tvhome reset`, a burst of D-pad keys, then read "Janky frames".
- Real remote: the user presses Home, Back, app buttons, Input/Sources, Guide, Settings, mic and holds
  Volume Up; corroborate with `logcat` `START u0` lines (cleared beforehand).

## Privacy in screenshots

The Wi-Fi pill shows the network name (when location permission is granted), the stock home shows the
account avatar and "continue watching" rows. Blur them before any screenshot leaves the user's machine.
