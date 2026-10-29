#!/usr/bin/env bash
# Check the device still works after a change: Home, Settings, an app, and on a TV the sources drawer,
# Live TV and an HDMI input. Prints the resumed activity for each step, Wi-Fi state and new crashes,
# and leaves screenshots in <device-dir>/shots/<tag>-*.png for you to look at.
#
#   TV_HOST=<ip> UPSTREAM=<cleanyourtv> scripts/verify.sh <device-dir> <tag>
# Optional env:
#   VERIFY_APP=<package>          app to launch (default com.google.android.youtube.tv if installed)
#   VERIFY_TV=1                   also open the sources drawer (KEYCODE_TV_INPUT)
#   VERIFY_LIVETV=<pkg/.Activity> vendor Live TV activity, e.g. org.droidtv.playtv/.PlayTvActivity
#   VERIFY_HDMI=<tv input id>     e.g. com.mediatek.tvinput/.hdmi.HDMIInputService/HW5
# Live TV, HDMI and video give empty or black screenshots: trust the activity lines there.
set -uo pipefail
. "$(cd "$(dirname "$0")" && pwd)/lib.sh"
dir="${1:?usage: verify.sh <device-dir> <tag>}"; tag="${2:?usage: verify.sh <device-dir> <tag>}"
require_device
mkdir -p "$dir/shots"
shot() { tv --screenshot "$dir/shots/$tag-$1.png" "${@:2}" >/dev/null 2>&1 || true; }

echo "== $tag"
shot 1-home HOME --wait 4;                    echo "home:     $(top_activity)"
if [ "${VERIFY_TV:-0}" = 1 ]; then
  shot 2-sources TV_INPUT --wait 3;           echo "sources:  $(top_activity)"
  tv 'input keyevent BACK' >/dev/null
fi
if [ -n "${VERIFY_LIVETV:-}" ]; then
  tv "am start -n $VERIFY_LIVETV" >/dev/null 2>&1; sleep 7; echo "livetv:   $(top_activity)"
fi
if [ -n "${VERIFY_HDMI:-}" ]; then
  uri="content://android.media.tv/passthrough/$(printf '%s' "$VERIFY_HDMI" | sed 's#/#%2F#g')"
  tv "am start -a android.intent.action.VIEW -d $uri" >/dev/null 2>&1; sleep 6; echo "hdmi:     $(top_activity)"
fi
tv 'am start -a android.settings.SETTINGS' >/dev/null 2>&1; sleep 4
shot 3-settings;                              echo "settings: $(top_activity)"
app="${VERIFY_APP:-}"
if [ -z "$app" ] && tv 'pm list packages -e com.google.android.youtube.tv' | grep -q youtube; then
  app=com.google.android.youtube.tv
fi
if [ -n "$app" ]; then
  tv "monkey -p $app -c android.intent.category.LEANBACK_LAUNCHER 1" >/dev/null 2>&1; sleep 10
  shot 4-app;                                 echo "app:      $(top_activity)"
  tv "am force-stop $app" >/dev/null
fi
shot 5-home HOME --wait 4;                    echo "home2:    $(top_activity)"
echo "network:  $(tv 'dumpsys connectivity' | grep -oE 'Transports: [A-Z]+' | sort -u | tr '\n' ' ')"
echo "crashes since last check:"
tv 'logcat -d -b crash' | grep -E 'Process:' | sort | uniq -c | head -10
tv 'logcat -b crash -c' >/dev/null
exit 0
