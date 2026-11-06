#!/bin/sh
# Fails unless every TOC carries the same version, and, when a tag is given (v0.1.0 or 0.1.0),
# that tag too; also fails unless CHANGELOG.md has a section for that version.
# Usage: tools/check-version.sh [tag]
dir=ClosestVendor
want=$(printf '%s' "${1#v}")
status=0
first=
for toc in "$dir"/ClosestVendor_*.toc; do
  v=$(sed -n 's/^## Version:[[:space:]]*//p' "$toc" | tr -d '\r')
  [ -z "$first" ] && first=$v
  if [ -z "$v" ] || [ "$v" != "$first" ]; then echo "VERSION  $(basename "$toc") has '$v', expected '$first'"; status=1; else echo "ok       $(basename "$toc") $v"; fi
  if [ -n "$want" ] && [ "$v" != "$want" ]; then echo "TAG      $(basename "$toc") has '$v' but the tag is '$want'"; status=1; fi
done
if [ -n "$first" ]; then
  if grep -q "^## $first\$" CHANGELOG.md 2>/dev/null; then echo "ok       CHANGELOG.md has $first"; else echo "CHANGELOG CHANGELOG.md has no '## $first' section"; status=1; fi
fi
exit $status
