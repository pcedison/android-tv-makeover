#!/usr/bin/env bash
# Shared helpers for the android-tv-makeover scripts. Source it, don't run it.
#   TV_HOST   device IP (or IP:port), as for upstream tools/tv.py
#   UPSTREAM  path to the cleanyourtv clone (with tools/venv set up)
# Commands go through a function, never a string variable: zsh does not word-split, and
# project paths often contain spaces.

: "${TV_HOST:?set TV_HOST to the device IP}"
: "${UPSTREAM:?set UPSTREAM to the cleanyourtv clone, e.g. UPSTREAM=\$PWD/cleanyourtv}"
export TV_HOST

[ -x "$UPSTREAM/tools/venv/bin/python" ] || {
  echo "missing $UPSTREAM/tools/venv: python3 -m venv \"$UPSTREAM/tools/venv\" &&" \
       "\"$UPSTREAM/tools/venv/bin/pip\" install -r \"$UPSTREAM/tools/requirements.txt\"" >&2
  exit 1
}

tv() { "$UPSTREAM/tools/venv/bin/python" "$UPSTREAM/tools/tv.py" "$@"; }

# Stop early when the device does not answer: an unreachable TV would otherwise print empty results
# that look like "nothing changed".
require_device() {
  if [ "$(tv 'echo adb-ok' 2>/dev/null | tr -d '\r')" != "adb-ok" ]; then
    echo "no answer from $TV_HOST over ADB: is debugging on, and is port 5555 open (adb tcpip 5555 on Google TV)?" >&2
    exit 3
  fi
}

# The resumed activity, e.g. com.gathin.tvhome/.MainActivity
top_activity() {
  tv 'dumpsys activity activities' | grep -m1 -E 'mResumedActivity|topResumedActivity' \
    | sed -E 's/.*u0 ([^ }]+).*/\1/'
}
