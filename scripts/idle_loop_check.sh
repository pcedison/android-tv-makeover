#!/usr/bin/env bash
# Look for retry loops left behind by disabled packages: a persistent process can keep its PID and
# retry a binding forever. Clears logcat, waits 30 s on Home, then lists the most frequent lines
# (digits collapsed) and any line that names a package from the debloat list.
#   TV_HOST=<ip> UPSTREAM=<cleanyourtv> scripts/idle_loop_check.sh <device-dir> [seconds]
set -uo pipefail
. "$(cd "$(dirname "$0")" && pwd)/lib.sh"
dir="${1:?usage: idle_loop_check.sh <device-dir> [seconds]}"; secs="${2:-30}"
require_device
out="$dir/backup/idle-logcat-$(date +%Y%m%d-%H%M%S).txt"
mkdir -p "$dir/backup"
tv 'input keyevent HOME' >/dev/null; sleep 5
tv 'logcat -c' >/dev/null; sleep "$secs"
tv 'logcat -d' > "$out"
echo "$(wc -l < "$out" | tr -d ' ') lines in ${secs}s idle -> $out"
echo "most repeated (anything several times a second is a loop):"
sed -E 's/^[0-9-]+ [0-9:.]+ +[0-9]+ +[0-9]+ //; s/[0-9]+/#/g' "$out" | sort | uniq -c | sort -rn | head -12 | cut -c1-180
list="$dir/lists/debloat.txt"
if [ -r "$list" ]; then
  pat=$(grep -v '^[[:space:]]*#' "$list" | awk 'NF{print $1}' | sed 's/\./\\./g' | paste -sd'|' -)
  if [ -n "$pat" ]; then
    hits=$(grep -cE "$pat" "$out" || true)
    echo "lines naming a disabled package: $hits"
    grep -E "$pat" "$out" | cut -c1-200 | head -10
  fi
fi
echo "note: with USB debugging on and no cable, adbd logs UsbFfs retries about once a second; that goes away when debugging is off."
exit 0
