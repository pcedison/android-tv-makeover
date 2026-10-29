#!/usr/bin/env bash
# Read-only snapshot of a device before anything changes.
#   TV_HOST=<ip> UPSTREAM=<cleanyourtv> scripts/backup.sh <device-dir>
# Writes <device-dir>/backup/*.txt and prints a short summary (HOME, Wi-Fi owner, IME, display).
set -euo pipefail
. "$(cd "$(dirname "$0")" && pwd)/lib.sh"
dir="${1:?usage: backup.sh <device-dir>}"
b="$dir/backup"
require_device
mkdir -p "$b"

tv 'pm list packages -f -U' > "$b/packages-all.txt"
tv 'pm list packages -d'    > "$b/packages-disabled.txt"
tv 'pm list packages -e'    > "$b/packages-enabled.txt"
tv 'pm list packages -s'    > "$b/packages-system.txt"
tv 'pm list packages -3'    > "$b/packages-thirdparty.txt"
tv 'getprop'                > "$b/getprop.txt"
tv 'settings list global'   > "$b/settings-global.txt"
tv 'settings list secure'   > "$b/settings-secure.txt"
tv 'settings list system'   > "$b/settings-system.txt"
{ tv 'wm size'; tv 'wm density'
  echo "display_density_forced=$(tv 'settings get secure display_density_forced')"; } > "$b/display.txt"
tv 'cmd package resolve-activity --brief -a android.intent.action.MAIN -c android.intent.category.HOME' > "$b/home-resolve.txt"
tv 'cmd package query-activities --brief -a android.intent.action.MAIN -c android.intent.category.HOME' > "$b/home-candidates.txt"
tv 'dumpsys wifi' | grep -o 'cname=[^ ]*' | sort -u > "$b/wifi-creators.txt" || true
tv 'settings get secure default_input_method'  > "$b/ime-default.txt"
tv 'settings get secure screensaver_components' > "$b/screensaver.txt"
tv 'settings get secure enabled_accessibility_services' > "$b/accessibility.txt"
{ echo "private_dns_mode=$(tv 'settings get global private_dns_mode')"
  echo "private_dns_specifier=$(tv 'settings get global private_dns_specifier')"; } > "$b/private-dns.txt"

empty=0
for f in "$b"/*.txt; do [ -s "$f" ] || { echo "EMPTY: $f"; empty=1; }; done
echo "backup: $(ls "$b" | wc -l | tr -d ' ') files in $b"
echo "packages: $(wc -l < "$b/packages-all.txt" | tr -d ' ') total," \
     "$(wc -l < "$b/packages-disabled.txt" | tr -d ' ') already disabled," \
     "$(wc -l < "$b/packages-thirdparty.txt" | tr -d ' ') user-installed"
echo "HOME: $(tail -1 "$b/home-resolve.txt")"
echo "Wi-Fi owner(s): $(tr '\n' ' ' < "$b/wifi-creators.txt")"
echo "IME: $(cat "$b/ime-default.txt")   screensaver: $(cat "$b/screensaver.txt")"
tr '\n' ' ' < "$b/display.txt"; echo
exit 0
