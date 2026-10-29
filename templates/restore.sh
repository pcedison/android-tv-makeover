#!/usr/bin/env bash
# Undo the makeover on <DEVICE NAME>. Copy into the device folder, fill in the three values below from
# backup/, and test it on one harmless package before relying on it:
#   DEBLOAT_LIST=<file with one package> TV_HOST=<ip> ./restore.sh
#
#   TV_HOST=<ip> ./restore.sh             re-enable every package in lists/debloat.txt
#   TV_HOST=<ip> ./restore.sh --launcher  also bring back the stock home (and screensaver)
#   TV_HOST=<ip> ./restore.sh --dns       also switch the ad-blocking Private DNS off
#   TV_HOST=<ip> ./restore.sh --all       all of the above
set -euo pipefail

# --- fill in from backup/ ---------------------------------------------------------------------
STOCK_HOME="com.google.android.tvlauncher/.MainActivity"  # backup/home-resolve.txt, last line
STOCK_EXTRA_PKGS=""        # packages the launcher step disabled, e.g. com.google.android.tungsten.setupwraith
STOCK_SCREENSAVER=""       # backup/screensaver.txt, only if you changed screensaver_components
# ----------------------------------------------------------------------------------------------

here="$(cd "$(dirname "$0")" && pwd)"
UPSTREAM="${UPSTREAM:-$here/../cleanyourtv}"
tv() { "$UPSTREAM/tools/venv/bin/python" "$UPSTREAM/tools/tv.py" "$@"; }  # a function: paths may contain spaces
: "${TV_HOST:?set TV_HOST to the device IP}"
export TV_HOST
list="${DEBLOAT_LIST:-$here/lists/debloat.txt}"

launcher=0; dns=0
for a in "$@"; do
  case "$a" in
    --launcher) launcher=1 ;;
    --dns) dns=1 ;;
    --all) launcher=1; dns=1 ;;
    *) echo "unknown option: $a" >&2; exit 2 ;;
  esac
done

{
  grep -v '^[[:space:]]*#' "$list" | awk 'NF {print "pm enable " $1}'
  if [ "$launcher" = 1 ]; then
    echo "pm enable ${STOCK_HOME%%/*}"
    for p in $STOCK_EXTRA_PKGS; do echo "pm enable $p"; done
    echo "cmd package set-home-activity $STOCK_HOME"
    [ -n "$STOCK_SCREENSAVER" ] && echo "settings put secure screensaver_components $STOCK_SCREENSAVER"
  fi
  [ "$dns" = 1 ] && echo "settings put global private_dns_mode opportunistic"
  echo "pm list packages -d"
} | tv --batch

echo
echo "Done. Packages still listed above as disabled were disabled before the makeover (see backup/packages-disabled.txt)."
[ "$launcher" = 1 ] && echo "Press Home on the remote: the stock home should open."
exit 0
