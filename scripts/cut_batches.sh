#!/usr/bin/env bash
# Split a debloat list into batch files by its "## batch N - title" markers.
#   scripts/cut_batches.sh <device-dir>/lists/debloat.txt
# Writes batch1.txt, batch2.txt ... next to it (package lines with their comments; headers dropped)
# and prints the package count per batch. Upstream tools/disable.sh reads these files.
set -euo pipefail
list="${1:?usage: cut_batches.sh <path to debloat.txt>}"
[ -r "$list" ] || { echo "cannot read $list" >&2; exit 1; }
out="$(cd "$(dirname "$list")" && pwd)"
rm -f "$out"/batch[0-9]*.txt
awk -v out="$out" '
  /^## batch [0-9]+/ { n = $3; f = out "/batch" n ".txt"; print "# cut from debloat.txt: " substr($0, 4) > f; next }
  n && !/^[[:space:]]*#/ && NF { print >> f }
' "$list"
found=0
for f in "$out"/batch[0-9]*.txt; do
  [ -e "$f" ] || continue
  found=1
  printf '%s: %s packages\n' "$(basename "$f")" "$(grep -vc '^#' "$f" || true)"
done
[ "$found" = 1 ] || { echo "no '## batch N' markers found in $list" >&2; exit 1; }
