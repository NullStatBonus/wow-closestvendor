#!/bin/sh
# Fails if the per-client TOC files list different files. Usage: tools/check-tocs-match.sh
dir=ClosestVendor
entries() { grep -v -e '^#' -e '^[[:space:]]*$' "$1" | tr -d '\r'; }
base=$(entries "$dir/ClosestVendor_Camelot.toc")
status=0
for toc in "$dir"/ClosestVendor_*.toc; do
  if [ "$base" = "$(entries "$toc")" ]; then echo "ok       $(basename "$toc")"; else echo "DIFFERS  $(basename "$toc")"; status=1; fi
done
exit $status
