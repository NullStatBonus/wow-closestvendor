#!/bin/sh
# Verifies a TOC: it has an Interface line, every file it lists exists, and every .lua file in
# the addon folder is listed (Locales/Example.lua is a template and is exempt).
# Usage: tools/check-toc.sh [path/to/file.toc]   (run from the repository root)
toc="${1:-ClosestVendor/ClosestVendor_Camelot.toc}"
dir=$(dirname "$toc")
status=0
listed=$(grep -v -e '^#' -e '^[[:space:]]*$' "$toc" | tr -d '\r' | tr '\\' '/')
for entry in $listed; do
  if [ -f "$dir/$entry" ]; then echo "ok       $entry"; else echo "MISSING  $entry"; status=1; fi
done
grep -q '^## Interface: ' "$toc" || { echo "MISSING  ## Interface line"; status=1; }
for file in $(cd "$dir" && find . -name '*.lua' | sed 's|^\./||' | sort); do
  [ "$file" = "Locales/Example.lua" ] && continue
  printf '%s\n' "$listed" | grep -qx "$file" || { echo "UNLISTED $file (not in $(basename "$toc"))"; status=1; }
done
# Embedded dependencies and notices must travel in the standalone package.
if printf '%s\n' "$listed" | grep -q '^Libs/'; then
  for notice in Libs/LICENSE.txt Libs/PROVENANCE.md; do
    [ -f "$dir/$notice" ] || { echo "MISSING  $notice"; status=1; }
  done
  previous=0
  for dependency in Libs/LibStub/LibStub.lua Libs/CallbackHandler-1.0/CallbackHandler-1.0.lua Libs/AceGUI-3.0/AceGUI-3.0.lua Libs/AceConfig-3.0/AceConfigRegistry-3.0/AceConfigRegistry-3.0.lua Libs/AceConfig-3.0/AceConfigDialog-3.0/AceConfigDialog-3.0.lua Options.lua; do
    line=$(printf '%s\n' "$listed" | awk -v path="$dependency" '$0 == path { print NR; exit }')
    if [ -z "$line" ] || [ "$line" -le "$previous" ]; then
      echo "ORDER    $dependency (missing or before its dependencies)"; status=1
    else previous=$line; fi
  done
fi
exit $status
