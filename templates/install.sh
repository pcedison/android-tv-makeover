#!/usr/bin/env bash
# Build and install the launcher on <DEVICE NAME>, then apply this device's theme and settings.
# Copy into the device folder and adjust the KEY SERVICES and POST-INSTALL sections.
#   TV_HOST=<ip> ./install.sh
# Needs JDK 17 and Android SDK platform 34 + build-tools 34.0.0 (see the skill's references/launcher.md).
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
UPSTREAM="${UPSTREAM:-$here/../cleanyourtv}"
tv() { "$UPSTREAM/tools/venv/bin/python" "$UPSTREAM/tools/tv.py" "$@"; }
: "${TV_HOST:?set TV_HOST to the device IP}"
export TV_HOST
export JAVA_HOME="${JAVA_HOME:-/opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home}"
export ANDROID_HOME="${ANDROID_HOME:-/opt/homebrew/share/android-commandlinetools}"
[ -x "$JAVA_HOME/bin/java" ] || { echo "JDK 17 not found at $JAVA_HOME" >&2; exit 1; }
[ -d "$ANDROID_HOME/platforms/android-34" ] || { echo "Android SDK platform 34 missing under $ANDROID_HOME" >&2; exit 1; }

# --- KEY SERVICES ------------------------------------------------------------------------------
# Google TV: the remote's YouTube key needs app_keys (theme) + HOME_KEY_SERVICE=1.
# Most TVs with a vendor key handler need none: leave both at 0.
export HOME_KEY_SERVICE="${HOME_KEY_SERVICE:-0}"
export RESTORE_KEY_SERVICES="${RESTORE_KEY_SERVICES:-0}"
# ----------------------------------------------------------------------------------------------

(cd "$UPSTREAM" && launcher/build-and-install.sh)

if [ -f "$here/theme/config.json" ]; then
  "$UPSTREAM/tools/theme.sh" "$here/theme"
fi

# --- POST-INSTALL settings (uncomment what applies) ----------------------------------------------
# tv 'settings put secure screensaver_components com.gathin.tvhome/.ClockDream'
# tv 'ime set com.google.android.inputmethod.latin/com.android.inputmethod.latin.LatinIME'
# ----------------------------------------------------------------------------------------------

echo
echo "Home:        $(tv 'cmd package resolve-activity --brief -a android.intent.action.MAIN -c android.intent.category.HOME' | tail -1)"
echo "Key service: $(tv 'settings get secure enabled_accessibility_services')"
echo "Press Home on the remote, then check: dumpsys activity activities | grep mFocusedApp"
